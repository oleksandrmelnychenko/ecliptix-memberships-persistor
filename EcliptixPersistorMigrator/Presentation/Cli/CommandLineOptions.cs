using CommandLine;
using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Enums;

namespace EcliptixPersistorMigrator.Presentation.Cli;

public abstract class BaseOptions
{
    [Option('s', "connectionstring", Required = false,
        HelpText = "Database connection string (overrides appsettings.json)")]
    public string? ConnectionString { get; set; }

    [Option('v', "verbose", Required = false,
        HelpText = "Enable verbose logging")]
    public bool Verbose { get; set; }
}

[Verb("migrate", HelpText = "Apply pending migrations to the database")]
public sealed class MigrateOptions : BaseOptions
{
    [Option('d', "dryrun", Required = false,
        HelpText = "Perform a dry run without executing changes")]
    public bool DryRun { get; set; }

    [Option('f', "force", Required = false,
        HelpText = "Force execution even if validation warnings exist")]
    public bool Force { get; set; }

    [Option('t', "target", Required = false,
        HelpText = "Target migration version to migrate to")]
    public string? TargetVersion { get; set; }

    [Option('b', "backup", Required = false,
        HelpText = "Create backup before migration")]
    public bool CreateBackup { get; set; }

    public ExecutionMode GetExecutionMode()
    {
        if (DryRun) return ExecutionMode.DryRun;
        if (Force) return ExecutionMode.Force;
        if (Verbose) return ExecutionMode.Verbose;
        return ExecutionMode.Normal;
    }
}

[Verb("status", HelpText = "Show current migration status")]
public sealed class StatusOptions : BaseOptions
{
    [Option('j', "json", Required = false,
        HelpText = "Output status in JSON format")]
    public bool JsonOutput { get; set; }
}

[Verb("rollback", HelpText = "Rollback to a specific migration version")]
public sealed class RollbackOptions : BaseOptions
{
    [Option('t', "target", Required = true,
        HelpText = "Target version to rollback to")]
    public string TargetVersion { get; set; } = string.Empty;

    [Option('d', "dryrun", Required = false,
        HelpText = "Perform a dry run without executing changes")]
    public bool DryRun { get; set; }

    [Option('f', "force", Required = false,
        HelpText = "Force rollback without confirmation")]
    public bool Force { get; set; }
}

[Verb("seed", HelpText = "Apply seed data to the database")]
public sealed class SeedOptions : BaseOptions
{
    [Option('d', "dryrun", Required = false,
        HelpText = "Perform a dry run without executing changes")]
    public bool DryRun { get; set; }

    [Option('n', "name", Required = false,
        HelpText = "Specific seed script to execute")]
    public string? SeedName { get; set; }
}

[Verb("validate", HelpText = "Validate migration scripts without executing")]
public sealed class ValidateOptions : BaseOptions
{
    [Option('n', "name", Required = false,
        HelpText = "Specific migration to validate")]
    public string? MigrationName { get; set; }
}

[Verb("backup", HelpText = "Create a database backup")]
public sealed class BackupOptions : BaseOptions
{
    [Option('n', "name", Required = false,
        HelpText = "Backup name (auto-generated if not provided)")]
    public string? BackupName { get; set; }

    [Option('p', "path", Required = false,
        HelpText = "Backup file path")]
    public string? BackupPath { get; set; }
}

[Verb("restore", HelpText = "Restore from a database backup")]
public sealed class RestoreOptions : BaseOptions
{
    [Option('n', "name", Required = true,
        HelpText = "Backup name to restore from")]
    public string BackupName { get; set; } = string.Empty;

    [Option('f', "force", Required = false,
        HelpText = "Force restore without confirmation")]
    public bool Force { get; set; }
}

[Verb("test", HelpText = "Test database connection")]
public sealed class TestOptions : BaseOptions
{
}

[Verb("list", HelpText = "List all available migrations")]
public sealed class ListOptions : BaseOptions
{
    [Option('p', "pending", Required = false,
        HelpText = "Show only pending migrations")]
    public bool PendingOnly { get; set; }

    [Option('e', "executed", Required = false,
        HelpText = "Show only executed migrations")]
    public bool ExecutedOnly { get; set; }
}

[Verb("generate", HelpText = "Generate a new migration template")]
public sealed class GenerateOptions : BaseOptions
{
    [Value(Constants.ArrayIndices.First, Required = true, MetaName = "name",
        HelpText = "Migration name")]
    public string Name { get; set; } = string.Empty;

    [Option('s', "seed", Required = false,
        HelpText = "Generate seed script instead of migration")]
    public bool IsSeed { get; set; }
}