using CommandLine;
using DbUp;
using DbUp.Engine;
using Microsoft.Extensions.Configuration;
using Serilog;
using System.Reflection;

namespace EcliptixPersistorMigrator;

class Program
{
    public class Options
    {
        [Option('c', "command", Required = true, HelpText = "Command to execute: migrate, status, rollback, seed")]
        public string Command { get; set; } = "";

        [Option('s', "connectionstring", Required = false, HelpText = "Database connection string (overrides appsettings.json)")]
        public string? ConnectionString { get; set; }

        [Option('v', "version", Required = false, HelpText = "Target version for rollback command")]
        public string? Version { get; set; }

        [Option('d', "dryrun", Required = false, HelpText = "Perform a dry run without executing changes")]
        public bool DryRun { get; set; }

        [Option("verbose", Required = false, HelpText = "Enable verbose logging")]
        public bool Verbose { get; set; }
    }

    static int Main(string[] args)
    {
        // Configure Serilog
        Log.Logger = new LoggerConfiguration()
            .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
            .CreateLogger();

        var result = Parser.Default.ParseArguments<Options>(args)
            .WithParsed(opts => RunCommand(opts))
            .WithNotParsed(errs => Environment.Exit(1));

        Log.CloseAndFlush();
        return 0;
    }

    static void RunCommand(Options options)
    {
        try
        {
            // Load configuration
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false)
                .Build();

            var connectionString = options.ConnectionString
                ?? configuration.GetConnectionString("EcliptixMemberships")
                ?? throw new InvalidOperationException("No connection string provided");

            var migrator = new MigrationRunner(connectionString, options.Verbose);

            switch (options.Command.ToLower())
            {
                case "migrate":
                    migrator.RunMigrations(options.DryRun);
                    break;
                case "status":
                    migrator.ShowStatus();
                    break;
                case "rollback":
                    if (string.IsNullOrEmpty(options.Version))
                    {
                        Console.WriteLine("❌ Version parameter is required for rollback command");
                        Environment.Exit(1);
                    }
                    migrator.Rollback(options.Version, options.DryRun);
                    break;
                case "seed":
                    migrator.RunSeeds(options.DryRun);
                    break;
                default:
                    Console.WriteLine($"❌ Unknown command: {options.Command}");
                    Console.WriteLine("Available commands: migrate, status, rollback, seed");
                    Environment.Exit(1);
                    break;
            }
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "❌ Application terminated unexpectedly");
            Environment.Exit(1);
        }
    }
}

public class MigrationRunner
{
    private readonly string _connectionString;
    private readonly bool _verbose;

    public MigrationRunner(string connectionString, bool verbose = false)
    {
        _connectionString = connectionString;
        _verbose = verbose;
    }

    public void RunMigrations(bool dryRun = false)
    {
        Console.WriteLine("🚀 Starting database migrations...");

        if (dryRun)
        {
            Console.WriteLine("🔍 DRY RUN MODE - No changes will be made");
        }

        var upgrader = DeployChanges.To
            .SqlDatabase(_connectionString)
            .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
                script => script.StartsWith("EcliptixPersistorMigrator.Migrations.V") &&
                         script.EndsWith(".sql"))
            .WithTransactionPerScript()
            .JournalToSqlTable("dbo", "SchemaVersions")
            .LogToConsole()
            .WithVariablesDisabled()
            .Build();

        if (dryRun)
        {
            var scriptsToExecute = upgrader.GetScriptsToExecute();
            if (scriptsToExecute.Any())
            {
                Console.WriteLine($"📄 Would execute {scriptsToExecute.Count()} migrations:");
                foreach (var script in scriptsToExecute)
                {
                    Console.WriteLine($"  • {script.Name}");
                }
            }
            else
            {
                Console.WriteLine("✅ Database is up to date - no migrations to run");
            }
            return;
        }

        var result = upgrader.PerformUpgrade();

        if (!result.Successful)
        {
            Console.WriteLine($"❌ Migration failed: {result.Error}");
            if (_verbose && result.ErrorScript != null)
            {
                Console.WriteLine($"Failed script: {result.ErrorScript.Name}");
            }
            Environment.Exit(1);
        }

        Console.WriteLine("✅ Database migrations completed successfully!");

        if (result.Scripts.Any())
        {
            Console.WriteLine($"📊 Executed {result.Scripts.Count()} migrations:");
            foreach (var script in result.Scripts)
            {
                Console.WriteLine($"  ✓ {script.Name}");
            }
        }
    }

    public void RunSeeds(bool dryRun = false)
    {
        Console.WriteLine("🌱 Starting seed data deployment...");

        if (dryRun)
        {
            Console.WriteLine("🔍 DRY RUN MODE - No changes will be made");
        }

        var upgrader = DeployChanges.To
            .SqlDatabase(_connectionString)
            .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
                script => script.StartsWith("EcliptixPersistorMigrator.Migrations.Seeds.S") &&
                         script.EndsWith(".sql"))
            .WithTransactionPerScript()
            .JournalToSqlTable("dbo", "SeedVersions")
            .LogToConsole()
            .WithVariablesDisabled()
            .Build();

        if (dryRun)
        {
            var scriptsToExecute = upgrader.GetScriptsToExecute();
            if (scriptsToExecute.Any())
            {
                Console.WriteLine($"📄 Would execute {scriptsToExecute.Count()} seed scripts:");
                foreach (var script in scriptsToExecute)
                {
                    Console.WriteLine($"  • {script.Name}");
                }
            }
            else
            {
                Console.WriteLine("✅ All seed data is up to date");
            }
            return;
        }

        var result = upgrader.PerformUpgrade();

        if (!result.Successful)
        {
            Console.WriteLine($"❌ Seed deployment failed: {result.Error}");
            Environment.Exit(1);
        }

        Console.WriteLine("✅ Seed data deployed successfully!");
    }

    public void ShowStatus()
    {
        Console.WriteLine("📊 Database Migration Status");
        Console.WriteLine("═══════════════════════════");

        try
        {
            var upgrader = DeployChanges.To
                .SqlDatabase(_connectionString)
                .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
                    script => script.StartsWith("EcliptixPersistorMigrator.Migrations.V") &&
                             script.EndsWith(".sql"))
                .JournalToSqlTable("dbo", "SchemaVersions")
                .LogToNowhere()
                .Build();

            var executedScripts = upgrader.GetExecutedScripts();
            var scriptsToExecute = upgrader.GetScriptsToExecute();

            Console.WriteLine($"✅ Executed migrations: {executedScripts.Count()}");
            foreach (var script in executedScripts)
            {
                Console.WriteLine($"  ✓ {script}");
            }

            if (scriptsToExecute.Any())
            {
                Console.WriteLine($"⏳ Pending migrations: {scriptsToExecute.Count()}");
                foreach (var script in scriptsToExecute)
                {
                    Console.WriteLine($"  ⏳ {script.Name}");
                }
            }
            else
            {
                Console.WriteLine("✅ Database is up to date");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Error checking status: {ex.Message}");
        }
    }

    public void Rollback(string version, bool dryRun = false)
    {
        Console.WriteLine($"⚠️  Rollback functionality is not implemented yet");
        Console.WriteLine($"Target version: {version}");
        Console.WriteLine("This is a placeholder for future rollback implementation");

        if (dryRun)
        {
            Console.WriteLine("🔍 DRY RUN MODE - Would show rollback plan here");
        }
    }
}
