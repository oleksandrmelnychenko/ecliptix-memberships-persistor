using CommandLine;
using EcliptixPersistorMigrator.Application.Commands;
using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Presentation.Cli;

public sealed class CliRunner
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<CliRunner> _logger;

    public CliRunner(IServiceProvider serviceProvider, ILogger<CliRunner> logger)
    {
        _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<int> RunAsync(string[] args)
    {
        if (args?.Length == Constants.Numeric.Zero)
        {
            ShowHelp();
            return Constants.ExitCodes.Success;
        }

        try
        {
            int result = await Parser.Default.ParseArguments<
                MigrateOptions,
                StatusOptions,
                RollbackOptions,
                SeedOptions,
                ValidateOptions,
                TestOptions,
                BackupOptions,
                RestoreOptions,
                ListOptions,
                GenerateOptions
            >(args)
                .MapResult(
                    (MigrateOptions opts) => ExecuteCommandAsync<MigrateOptions, MigrateCommand>(opts),
                    (StatusOptions opts) => ExecuteCommandAsync<StatusOptions, StatusCommand>(opts),
                    (RollbackOptions opts) => ExecuteCommandAsync<RollbackOptions, RollbackCommand>(opts),
                    (SeedOptions opts) => ExecuteCommandAsync<SeedOptions, SeedCommand>(opts),
                    (ValidateOptions opts) => ExecuteCommandAsync<ValidateOptions, ValidateCommand>(opts),
                    (TestOptions opts) => ExecuteCommandAsync<TestOptions, TestCommand>(opts),
                    (BackupOptions opts) => ExecuteCommandAsync<BackupOptions, BackupCommand>(opts),
                    (RestoreOptions opts) => ExecuteCommandAsync<RestoreOptions, RestoreCommand>(opts),
                    (ListOptions opts) => ExecuteCommandAsync<ListOptions, ListCommand>(opts),
                    (GenerateOptions opts) => ExecuteCommandAsync<GenerateOptions, GenerateCommand>(opts),
                    errors => HandleParseErrorsAsync(errors)
                );

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error in CLI runner");
            Console.WriteLine($"❌ Unexpected error: {ex.Message}");
            return Constants.ExitCodes.Error;
        }
    }

    private async Task<int> ExecuteCommandAsync<TOptions, TCommand>(TOptions options)
        where TCommand : BaseCommand<TOptions>
        where TOptions : BaseOptions
    {
        try
        {
            ConfigureConnectionString(options);

            TCommand command = _serviceProvider.GetRequiredService<TCommand>();
            command.Options = options;

            _logger.LogDebug("Executing command {CommandType} with options {@Options}",
                typeof(TCommand).Name, options);

            CommandResult result = await command.ExecuteAsync();

            if (result.IsSuccess)
            {
                if (!string.IsNullOrWhiteSpace(result.Message) && options.Verbose)
                {
                    Console.WriteLine(result.Message);
                }
            }
            else
            {
                Console.WriteLine(result.Message ?? "Command execution failed");
                if (result.Exception != null && options.Verbose)
                {
                    Console.WriteLine($"Details: {result.Exception.Message}");
                }
            }

            return result.ExitCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing command {CommandType}", typeof(TCommand).Name);
            Console.WriteLine($"❌ Error executing command: {ex.Message}");
            return Constants.ExitCodes.Error;
        }
    }

    private static void ConfigureConnectionString(BaseOptions options)
    {
        if (!string.IsNullOrWhiteSpace(options.ConnectionString))
        {
            Environment.SetEnvironmentVariable(
                $"ConnectionStrings__{Constants.Database.DefaultConnectionStringKey}",
                options.ConnectionString);
        }
    }

    private async Task<int> HandleParseErrorsAsync(IEnumerable<Error> errors)
    {
        List<Error> errorList = errors.ToList();

        foreach (Error error in errorList)
        {
            if (error is HelpRequestedError or VersionRequestedError)
            {
                return Constants.ExitCodes.Success;
            }

            _logger.LogWarning("Command line parsing error: {ErrorType}", error.GetType().Name);
        }

        Console.WriteLine("❌ Invalid command line arguments. Use --help for usage information.");
        return Constants.ExitCodes.InvalidArguments;
    }

    private static void ShowHelp()
    {
        Console.WriteLine("🚀 EcliptixPersistorMigrator - Professional Database Migration Tool");
        Console.WriteLine();
        Console.WriteLine("Available Commands:");
        Console.WriteLine("  migrate     Apply pending migrations to the database");
        Console.WriteLine("  status      Show current migration status");
        Console.WriteLine("  rollback    Rollback to a specific migration version");
        Console.WriteLine("  seed        Apply seed data to the database");
        Console.WriteLine("  validate    Validate migration scripts without executing");
        Console.WriteLine("  test        Test database connection");
        Console.WriteLine("  backup      Create a database backup");
        Console.WriteLine("  restore     Restore from a database backup");
        Console.WriteLine("  list        List all available migrations");
        Console.WriteLine("  generate    Generate a new migration template");
        Console.WriteLine();
        Console.WriteLine("Use 'command --help' for detailed information about each command.");
        Console.WriteLine();
        Console.WriteLine("Examples:");
        Console.WriteLine("  dotnet run migrate");
        Console.WriteLine("  dotnet run status --verbose");
        Console.WriteLine("  dotnet run migrate --dryrun");
        Console.WriteLine("  dotnet run test --connectionstring \"Server=...\"");
    }
}