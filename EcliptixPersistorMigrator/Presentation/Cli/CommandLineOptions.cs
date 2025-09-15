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


[Verb("test", HelpText = "Test database connection")]
public sealed class TestOptions : BaseOptions
{
}

