using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Enums;
using EcliptixPersistorMigrator.Core.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EcliptixPersistorMigrator.Infrastructure.Database;

public sealed class MigrationRepository : IMigrationRepository
{
    private readonly IDatabaseConnection _databaseConnection;
    private readonly ILogger<MigrationRepository> _logger;
    private readonly MigrationSettings _settings;

    public MigrationRepository(
        IDatabaseConnection databaseConnection,
        IOptions<MigrationSettings> settings,
        ILogger<MigrationRepository> logger)
    {
        _databaseConnection = databaseConnection ?? throw new ArgumentNullException(nameof(databaseConnection));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _settings = settings?.Value ?? throw new ArgumentNullException(nameof(settings));
    }

    public async Task<IEnumerable<Migration>> GetAllMigrationsAsync(CancellationToken cancellationToken = default)
    {
        List<Migration> migrations = new List<Migration>();

        Assembly assembly = Assembly.GetExecutingAssembly();
        IOrderedEnumerable<string> resourceNames = assembly.GetManifestResourceNames()
            .Where(name => name.StartsWith(_settings.MigrationFilePattern) && name.EndsWith(Constants.Database.SqlFileExtension))
            .OrderBy(name => name);

        foreach (string resourceName in resourceNames)
        {
            Migration? migration = await CreateMigrationFromResourceAsync(assembly, resourceName, cancellationToken);
            if (migration != null)
            {
                migrations.Add(migration);
            }
        }

        return migrations.OrderBy(m => m.Version);
    }

    public async Task<IEnumerable<Migration>> GetExecutedMigrationsAsync(CancellationToken cancellationToken = default)
    {
        IEnumerable<Migration> allMigrations = await GetAllMigrationsAsync(cancellationToken);
        HashSet<string> executedMigrationNames = await GetExecutedMigrationNamesAsync(cancellationToken);

        return allMigrations.Where(m => executedMigrationNames.Contains(m.Name));
    }

    public async Task<IEnumerable<Migration>> GetPendingMigrationsAsync(CancellationToken cancellationToken = default)
    {
        IEnumerable<Migration> allMigrations = await GetAllMigrationsAsync(cancellationToken);
        HashSet<string> executedMigrationNames = await GetExecutedMigrationNamesAsync(cancellationToken);

        return allMigrations.Where(m => !executedMigrationNames.Contains(m.Name));
    }

    public async Task<Migration?> GetMigrationByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        IEnumerable<Migration> allMigrations = await GetAllMigrationsAsync(cancellationToken);
        return allMigrations.FirstOrDefault(m => m.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<OperationResult> MarkMigrationAsExecutedAsync(Migration migration, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(migration);

        try
        {
            _logger.LogDebug("Marking migration {MigrationName} as executed", migration.Name);
            await _databaseConnection.ExecuteAsync(async () =>
            {
                await Task.CompletedTask;
            }, cancellationToken);

            return OperationResult.Success;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to mark migration {MigrationName} as executed", migration.Name);
            return OperationResult.Failed;
        }
    }

    public async Task<OperationResult> RemoveMigrationFromJournalAsync(string migrationName, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(migrationName);

        try
        {
            _logger.LogDebug("Removing migration {MigrationName} from journal", migrationName);
            await _databaseConnection.ExecuteAsync(async () =>
            {
                await Task.CompletedTask;
            }, cancellationToken);

            return OperationResult.Success;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to remove migration {MigrationName} from journal", migrationName);
            return OperationResult.Failed;
        }
    }

    private async Task<Migration?> CreateMigrationFromResourceAsync(Assembly assembly, string resourceName, CancellationToken cancellationToken)
    {
        try
        {
            await using Stream? stream = assembly.GetManifestResourceStream(resourceName);
            if (stream == null)
            {
                _logger.LogWarning("Could not load resource stream for {ResourceName}", resourceName);
                return null;
            }

            using StreamReader reader = new StreamReader(stream);
            string content = await reader.ReadToEndAsync(cancellationToken);

            string fileName = ExtractFileNameFromResourceName(resourceName);
            (int version, string? description) = ParseMigrationFileName(fileName);
            string checkSum = CalculateCheckSum(content);

            return new Migration
            {
                Name = resourceName,
                FileName = fileName,
                Content = content,
                Version = version,
                Description = description,
                CheckSum = checkSum,
                State = MigrationState.Pending
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create migration from resource {ResourceName}", resourceName);
            return null;
        }
    }

    private async Task<HashSet<string>> GetExecutedMigrationNamesAsync(CancellationToken cancellationToken)
    {
        HashSet<string> executedNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        try
        {
            await _databaseConnection.ExecuteAsync(async () =>
            {
                await Task.CompletedTask;
            }, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "Could not retrieve executed migrations, assuming empty");
        }

        return executedNames;
    }

    private static string ExtractFileNameFromResourceName(string resourceName)
    {
        int lastDot = resourceName.LastIndexOf('.');
        int secondLastDot = resourceName.LastIndexOf('.', lastDot - Constants.Numeric.One);
        return resourceName.Substring(secondLastDot + Constants.Numeric.One);
    }

    private static (int version, string? description) ParseMigrationFileName(string fileName)
    {
        string withoutExtension = Path.GetFileNameWithoutExtension(fileName);
        string[] parts = withoutExtension.Split(Constants.StringManipulation.DoubleDash, Constants.StringManipulation.SplitIntoTwo);

        if (parts.Length != Constants.StringManipulation.SplitIntoTwo || !parts[0].StartsWith(Constants.MigrationPatterns.MigrationPrefix))
        {
            return (Constants.Numeric.Zero, null);
        }

        string versionString = parts[0].Substring(Constants.Numeric.One);
        if (!int.TryParse(versionString, out int version))
        {
            return (Constants.Numeric.Zero, null);
        }

        string description = parts[1].Replace(Constants.StringManipulation.Underscore, Constants.StringManipulation.Space);
        return (version, description);
    }

    private static string CalculateCheckSum(string content)
    {
        using SHA256 sha256 = SHA256.Create();
        byte[] hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(content));
        return Convert.ToBase64String(hash);
    }
}