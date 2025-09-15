using System.ComponentModel.DataAnnotations;

namespace EcliptixPersistorMigrator.Configuration;

public sealed class AppSettings
{
    [Required]
    public ConnectionStringsSettings ConnectionStrings { get; set; } = new();

    [Required]
    public MigrationSettings MigrationSettings { get; set; } = new();
}

public sealed class ConnectionStringsSettings
{
    [Required]
    public string EcliptixMemberships { get; set; } = string.Empty;
}

public sealed class MigrationSettings
{
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

