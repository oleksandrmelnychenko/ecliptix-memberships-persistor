using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Enums;
using EcliptixPersistorMigrator.Core.Interfaces;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class MigrateCommand : BaseCommand<MigrateOptions>
{
    private readonly IMigrationRepository _migrationRepository;
    private readonly IMigrationEngine _migrationEngine;
    public MigrateCommand(
        IMigrationRepository migrationRepository,
        IMigrationEngine migrationEngine,
        ILogger<MigrateCommand> logger)
        : base(logger)
    {
        _migrationRepository = migrationRepository ?? throw new ArgumentNullException(nameof(migrationRepository));
        _migrationEngine = migrationEngine ?? throw new ArgumentNullException(nameof(migrationEngine));
    }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        ValidateOptions();

        ExecutionMode mode = Options.GetExecutionMode();

        if (Options.CreateBackup)
        {
            Logger.LogWarning("Backup functionality is not implemented yet");
        }

        IEnumerable<Migration> pendingMigrations = await _migrationRepository.GetPendingMigrationsAsync(cancellationToken);
        IEnumerable<Migration> migrationsToExecute = GetMigrationsToExecute(pendingMigrations);

        if (!migrationsToExecute.Any())
        {
            string message = "Database is up to date - no migrations to run";
            Logger.LogInformation(message);
            return CommandResult.NoChanges(message);
        }

        if (mode == ExecutionMode.DryRun)
        {
            return await HandleDryRunAsync(migrationsToExecute, cancellationToken);
        }

        return await ExecuteMigrationsAsync(migrationsToExecute, mode, cancellationToken);
    }

    private IEnumerable<Migration> GetMigrationsToExecute(IEnumerable<Migration> pendingMigrations)
    {
        IOrderedEnumerable<Migration> migrations = pendingMigrations.OrderBy(m => m.Version);

        if (!string.IsNullOrWhiteSpace(Options.TargetVersion))
        {
            if (!int.TryParse(Options.TargetVersion.TrimStart('V', 'v'), out int targetVersion))
            {
                throw new InvalidOperationException($"Invalid target version format: {Options.TargetVersion}");
            }

            migrations = migrations.Where(m => m.Version <= targetVersion).OrderBy(m => m.Version);
        }

        return migrations;
    }

    private async Task<CommandResult> HandleDryRunAsync(IEnumerable<Migration> migrations,
        CancellationToken cancellationToken)
    {
        List<Migration> migrationList = migrations.ToList();
        Logger.LogInformation("DRY RUN MODE - No changes will be made");
        Logger.LogInformation("Would execute {Count} migrations:", migrationList.Count);

        foreach (Migration migration in migrationList)
        {
            Logger.LogInformation("  • {MigrationName} - {Description}",
                migration.FileName, migration.Description ?? "No description");

            if (Options.Verbose)
            {
                var validationResult = await _migrationEngine.ValidateMigrationAsync(migration, cancellationToken);
                if (!validationResult.IsValid)
                {
                    Logger.LogWarning("    Validation errors found:");
                    foreach (ValidationError error in validationResult.Errors)
                    {
                        Logger.LogWarning("      - {ErrorMessage}", error.Message);
                    }
                }

                if (validationResult.Warnings.Any())
                {
                    Logger.LogWarning("    Validation warnings:");
                    foreach (ValidationWarning warning in validationResult.Warnings)
                    {
                        Logger.LogWarning("      - {WarningMessage}", warning.Message);
                    }
                }
            }
        }

        return CommandResult.Success($"Dry run completed. {migrationList.Count} migrations would be executed.",
            data: new Dictionary<string, object> { { "MigrationCount", migrationList.Count } });
    }

    private async Task<CommandResult> ExecuteMigrationsAsync(IEnumerable<Migration> migrations,
        ExecutionMode mode, CancellationToken cancellationToken)
    {
        List<Migration> migrationList = migrations.ToList();
        int executedCount = Constants.Numeric.Zero;
        List<string> failedMigrations = new List<string>();

        Logger.LogInformation("Starting database migrations...");
        Logger.LogInformation("Executing {Count} migrations", migrationList.Count);

        foreach (Migration migration in migrationList)
        {
            Logger.LogInformation("Executing migration: {MigrationName}", migration.FileName);

            if (mode != ExecutionMode.Force)
            {
                var validationResult = await _migrationEngine.ValidateMigrationAsync(migration, cancellationToken);
                if (!validationResult.IsValid)
                {
                    var errorMessage = $"Migration {migration.FileName} failed validation";
                    Logger.LogError(errorMessage);
                    foreach (ValidationError error in validationResult.Errors)
                    {
                        Logger.LogError("  - {ErrorMessage}", error.Message);
                    }
                    return CommandResult.Failure(errorMessage, exitCode: Constants.ExitCodes.ValidationError);
                }
            }

            var result = await _migrationEngine.ExecuteMigrationAsync(migration, mode, cancellationToken);
            if (result == OperationResult.Success)
            {
                executedCount++;
                Logger.LogInformation("✓ {MigrationName} completed successfully", migration.FileName);
            }
            else
            {
                failedMigrations.Add(migration.FileName);
                var errorMessage = $"Migration {migration.FileName} failed";
                Logger.LogError(errorMessage);
                return CommandResult.Failure(errorMessage, exitCode: Constants.ExitCodes.MigrationError);
            }
        }

        var successMessage = $"Database migrations completed successfully! Executed {executedCount} migrations.";
        Logger.LogInformation(successMessage);

        return CommandResult.Success(successMessage,
            data: new Dictionary<string, object>
            {
                { "ExecutedCount", executedCount },
                { "TotalCount", migrationList.Count },
                { "FailedMigrations", failedMigrations }
            });
    }

    protected override void ValidateOptions()
    {
        base.ValidateOptions();

        if (!string.IsNullOrWhiteSpace(Options.TargetVersion))
        {
            if (!Options.TargetVersion.StartsWith("V", StringComparison.OrdinalIgnoreCase) &&
                !int.TryParse(Options.TargetVersion, out _))
            {
                throw new ArgumentException("Target version must be in format 'V001' or '001'",
                    nameof(Options.TargetVersion));
            }
        }
    }
}