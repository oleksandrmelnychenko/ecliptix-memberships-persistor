using System.ComponentModel.DataAnnotations;

namespace EcliptixPersistorMigrator.Configuration;

public sealed class AppSettings
{
    public const string SectionName = "AppSettings";

    [Required]
    public ConnectionStringsSettings ConnectionStrings { get; set; } = new();

    [Required]
    public MigrationSettings MigrationSettings { get; set; } = new();

    public LoggingSettings Logging { get; set; } = new();
}

public sealed class ConnectionStringsSettings
{
    [Required]
    public string EcliptixMemberships { get; set; } = string.Empty;
}

public sealed class MigrationSettings
{
    public const string SectionName = "MigrationSettings";

    [Required]
    public string JournalTableName { get; set; } = Constants.Database.SchemaVersionsTable;

    [Required]
    public string JournalSchema { get; set; } = Constants.Database.DefaultSchema;

    public bool TransactionPerScript { get; set; } = true;

    public bool VariablesEnabled { get; set; } = false;

    public int CommandTimeout { get; set; } = Constants.Numeric.DefaultTimeout;

    public bool CreateSchemaVersionsTable { get; set; } = true;

    public string SeedJournalTableName { get; set; } = Constants.Database.SeedVersionsTable;

    public string MigrationFilePattern { get; set; } = Constants.MigrationPatterns.MigrationPattern;

    public string SeedFilePattern { get; set; } = Constants.MigrationPatterns.SeedPattern;
}

public sealed class LoggingSettings
{
    public const string SectionName = "Logging";

    public LogLevelSettings LogLevel { get; set; } = new();
}

public sealed class LogLevelSettings
{
    public string Default { get; set; } = "Information";
    public string Microsoft { get; set; } = "Warning";
    public string System { get; set; } = "Warning";
}