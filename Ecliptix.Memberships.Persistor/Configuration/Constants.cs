namespace Ecliptix.Memberships.Persistor.Configuration;

public static class Constants
{
    public static class Database
    {
        public const string DefaultConnectionStringKey = "EcliptixMemberships";
        public const string DefaultSchema = "dbo";
        public const string SchemaVersionsTable = "SchemaVersions";
        public const string SeedVersionsTable = "SeedVersions";
        public const string SqlFileExtension = ".sql";
    }

    public static class MigrationPatterns
    {
        public const string MigrationPrefix = "V";
        public const string SeedPrefix = "S";
        public const string MigrationPattern = "Ecliptix.Memberships.Persistor.Migrations.V";
        public const string SeedPattern = "Ecliptix.Memberships.Persistor.Migrations.Seeds.S";
    }

    public static class Files
    {
        public const string AppSettingsFileName = "appsettings.json";
    }

    public static class Logging
    {
        public const string OutputTemplate = "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}";
        public const string FatalMessage = "Application terminated unexpectedly";
    }

    public static class ExitCodes
    {
        public const int Success = 0;
        public const int Error = 1;
        public const int InvalidArguments = 2;
        public const int DatabaseConnectionError = 3;
        public const int MigrationError = 4;
        public const int ValidationError = 5;
    }

    public static class Configuration
    {
        public const string MigrationSettings = "MigrationSettings";
    }

    public static class Numeric
    {
        public const int Zero = 0;
        public const int One = 1;
        public const int DefaultTimeout = 30;
    }

    public static class StringManipulation
    {
        public const string DoubleDash = "__";
        public const char Underscore = '_';
        public const char Space = ' ';
        public const int SplitIntoTwo = 2;
    }

    public static class ArrayIndices
    {
        public const int First = 0;
        public const int Second = 1;
    }
}