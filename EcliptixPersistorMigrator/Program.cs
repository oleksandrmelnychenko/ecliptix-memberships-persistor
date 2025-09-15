using CommandLine;
using EcliptixPersistorMigrator.Application.Commands;
using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Enums;
using EcliptixPersistorMigrator.Core.Interfaces;
using EcliptixPersistorMigrator.Infrastructure.Database;
using EcliptixPersistorMigrator.Infrastructure.Migrations;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Serilog;
using Serilog.Extensions.Hosting;

namespace EcliptixPersistorMigrator;

internal static class Program
{
    private static async Task<int> Main(string[] args)
    {
        Log.Logger = new LoggerConfiguration()
            .WriteTo.Console(outputTemplate: Constants.Logging.OutputTemplate)
            .CreateLogger();

        try
        {
            IHost host = CreateHost(args);
            CliRunner runner = host.Services.GetRequiredService<CliRunner>();
            int exitCode = await runner.RunAsync(args);
            return exitCode;
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, Constants.Logging.FatalMessage);
            return Constants.ExitCodes.Error;
        }
        finally
        {
            await Log.CloseAndFlushAsync();
        }
    }

    private static IHost CreateHost(string[] args)
    {
        return Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((context, config) =>
            {
                config.SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile(Constants.Files.AppSettingsFileName, optional: false)
                    .AddEnvironmentVariables()
                    .AddCommandLine(args);
            })
            .ConfigureServices((context, services) =>
            {
                ConfigureServices(services, context.Configuration);
            })
            .UseSerilog()
            .Build();
    }

    private static void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<MigrationSettings>(configuration.GetSection(Constants.Configuration.MigrationSettings));
        services.Configure<AppSettings>(configuration);

        services.AddSingleton(provider =>
        {
            var connectionString = configuration.GetConnectionString(Constants.Database.DefaultConnectionStringKey)
                ?? throw new InvalidOperationException("Connection string not found");
            var logger = provider.GetRequiredService<ILogger<DatabaseConnection>>();
            return new DatabaseConnection(connectionString, logger);
        });

        services.AddTransient<IDatabaseConnection>(provider => provider.GetRequiredService<DatabaseConnection>());
        services.AddTransient<IMigrationRepository, MigrationRepository>();
        services.AddTransient<IMigrationEngine, MigrationEngine>();

        services.AddTransient<CommandFactory>();
        services.AddTransient<CliRunner>();

        RegisterCommands(services);
    }

    private static void RegisterCommands(IServiceCollection services)
    {
        services.AddTransient<MigrateCommand>();
        services.AddTransient<StatusCommand>();
        services.AddTransient<TestCommand>();
    }
}
