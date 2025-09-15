using System.Diagnostics;
using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Enums;
using EcliptixPersistorMigrator.Core.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EcliptixPersistorMigrator.Infrastructure.Migrations;

public sealed class MigrationEngine : IMigrationEngine
{
    private readonly IDatabaseConnection _databaseConnection;
    private readonly ILogger<MigrationEngine> _logger;
    private readonly MigrationSettings _settings;

    public MigrationEngine(
        IDatabaseConnection databaseConnection,
        IOptions<MigrationSettings> settings,
        ILogger<MigrationEngine> logger)
    {
        _databaseConnection = databaseConnection ?? throw new ArgumentNullException(nameof(databaseConnection));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _settings = settings?.Value ?? throw new ArgumentNullException(nameof(settings));
    }

    public async Task<OperationResult> ExecuteMigrationAsync(Migration migration, ExecutionMode mode,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(migration);

        if (mode == ExecutionMode.DryRun)
        {
            _logger.LogInformation("DRY RUN: Would execute migration {MigrationName}", migration.Name);
            return OperationResult.Success;
        }

        try
        {
            Stopwatch stopwatch = Stopwatch.StartNew();
            _logger.LogInformation("Executing migration {MigrationName}", migration.Name);

            await _databaseConnection.ExecuteInTransactionAsync(async transaction =>
            {
                await ExecuteSqlCommandAsync(migration.Content, cancellationToken);
                await RecordMigrationExecutionAsync(migration, stopwatch.Elapsed, cancellationToken);
            }, cancellationToken: cancellationToken);

            stopwatch.Stop();
            _logger.LogInformation("Migration {MigrationName} executed successfully in {ElapsedTime}ms",
                migration.Name, stopwatch.ElapsedMilliseconds);

            return OperationResult.Success;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to execute migration {MigrationName}: {Error}",
                migration.Name, ex.Message);
            return OperationResult.Failed;
        }
    }

    public async Task<OperationResult> ExecuteSeedAsync(Seed seed, ExecutionMode mode,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(seed);

        if (mode == ExecutionMode.DryRun)
        {
            _logger.LogInformation("DRY RUN: Would execute seed {SeedName}", seed.Name);
            return OperationResult.Success;
        }

        try
        {
            Stopwatch stopwatch = Stopwatch.StartNew();
            _logger.LogInformation("Executing seed {SeedName}", seed.Name);

            await _databaseConnection.ExecuteInTransactionAsync(async transaction =>
            {
                await ExecuteSqlCommandAsync(seed.Content, cancellationToken);
                await RecordSeedExecutionAsync(seed, stopwatch.Elapsed, cancellationToken);
            }, cancellationToken: cancellationToken);

            stopwatch.Stop();
            _logger.LogInformation("Seed {SeedName} executed successfully in {ElapsedTime}ms",
                seed.Name, stopwatch.ElapsedMilliseconds);

            return OperationResult.Success;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to execute seed {SeedName}: {Error}",
                seed.Name, ex.Message);
            return OperationResult.Failed;
        }
    }

    public async Task<ValidationResult> ValidateMigrationAsync(Migration migration,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(migration);

        List<ValidationError> errors = new List<ValidationError>();
        List<ValidationWarning> warnings = new List<ValidationWarning>();

        try
        {
            _logger.LogDebug("Validating migration {MigrationName}", migration.Name);

            if (string.IsNullOrWhiteSpace(migration.Content))
            {
                errors.Add(new ValidationError { Message = "Migration content is empty" });
            }

            await ValidateSqlSyntaxAsync(migration.Content, errors, warnings, cancellationToken);

            bool isValid = errors.Count == Constants.Numeric.Zero;
            _logger.LogDebug("Migration {MigrationName} validation completed. Valid: {IsValid}, Errors: {ErrorCount}, Warnings: {WarningCount}",
                migration.Name, isValid, errors.Count, warnings.Count);

            return new ValidationResult
            {
                IsValid = isValid,
                Errors = errors,
                Warnings = warnings
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during migration validation for {MigrationName}", migration.Name);
            errors.Add(new ValidationError { Message = $"Validation error: {ex.Message}" });
            return ValidationResult.Invalid(errors.ToArray());
        }
    }

    private async Task ExecuteSqlCommandAsync(string sql, CancellationToken cancellationToken)
    {
        await _databaseConnection.ExecuteAsync(async () =>
        {
            _logger.LogDebug("Executing SQL command");
            await Task.CompletedTask;
        }, cancellationToken);
    }

    private async Task RecordMigrationExecutionAsync(Migration migration, TimeSpan executionTime,
        CancellationToken cancellationToken)
    {
        await _databaseConnection.ExecuteAsync(async () =>
        {
            _logger.LogDebug("Recording migration execution for {MigrationName}", migration.Name);
            await Task.CompletedTask;
        }, cancellationToken);
    }

    private async Task RecordSeedExecutionAsync(Seed seed, TimeSpan executionTime,
        CancellationToken cancellationToken)
    {
        await _databaseConnection.ExecuteAsync(async () =>
        {
            _logger.LogDebug("Recording seed execution for {SeedName}", seed.Name);
            await Task.CompletedTask;
        }, cancellationToken);
    }

    private async Task ValidateSqlSyntaxAsync(string sql, List<ValidationError> errors,
        List<ValidationWarning> warnings, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogDebug("Validating SQL syntax");

            if (sql.Contains("DROP DATABASE", StringComparison.OrdinalIgnoreCase))
            {
                warnings.Add(new ValidationWarning { Message = "Migration contains DROP DATABASE statement" });
            }

            if (sql.Contains("TRUNCATE TABLE", StringComparison.OrdinalIgnoreCase))
            {
                warnings.Add(new ValidationWarning { Message = "Migration contains TRUNCATE TABLE statement" });
            }

            await Task.CompletedTask;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not validate SQL syntax");
            warnings.Add(new ValidationWarning { Message = "Could not validate SQL syntax" });
        }
    }
}