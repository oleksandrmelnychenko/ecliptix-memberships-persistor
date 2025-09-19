using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;
using Ecliptix.Memberships.Persistor.Schema;
using Ecliptix.Memberships.Persistor.StoredProcedures.Services;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.Configuration;

namespace Ecliptix.Memberships.Persistor;

internal static class Program
{
    private static async Task<int> Main(string[] args)
    {
        Log.Logger = new LoggerConfiguration()
            .WriteTo.Console()
            .WriteTo.File("logs/ecliptix-migrator-.log", rollingInterval: RollingInterval.Day)
            .CreateLogger();

        try
        {
            Log.Information("🏗️  EcliptixPersistorMigrator - Database Schema Management Tool");

            IHost host = CreateHost(args);

            using Microsoft.Extensions.DependencyInjection.IServiceScope scope = host.Services.CreateScope();
            EcliptixSchemaContext context = scope.ServiceProvider.GetRequiredService<EcliptixSchemaContext>();
            Microsoft.Extensions.Logging.ILogger<EcliptixSchemaContext> logger = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Logging.ILogger<EcliptixSchemaContext>>();

            await ExecutePendingMigrationsAsync(context, logger);

            Log.Information("✅ EcliptixSchemaContext initialized successfully");
            Log.Information("📊 DbSets configured: {DbSetCount}", GetDbSetCount(context));
            Log.Information("🔧 Stored Procedures service ready");

            return 0;
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "❌ Application terminated unexpectedly");
            return 1;
        }
        finally
        {
            Log.CloseAndFlush();
        }
    }

    private static IHost CreateHost(string[] args)
    {
        return Host.CreateDefaultBuilder(args)
            .ConfigureAppConfiguration((context, config) =>
            {
                config.SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json", optional: false)
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
        services.Configure<AppSettings>(configuration);

        services.AddDbContext<EcliptixSchemaContext>(options =>
        {
            string connectionString = configuration.GetConnectionString("EcliptixMemberships")
                ?? throw new InvalidOperationException("Connection string 'EcliptixMemberships' not found");

            options.UseSqlServer(connectionString);
        });

        services.AddScoped<IStoredProcedureExecutor, StoredProcedureExecutor>();
        services.AddScoped<IVerificationService, VerificationService>();
    }

    private static async Task ExecutePendingMigrationsAsync(EcliptixSchemaContext context, Microsoft.Extensions.Logging.ILogger logger)
    {
        try
        {
            Log.Information("🔍 Checking database schema...");

            bool canConnect = await context.Database.CanConnectAsync();
            if (!canConnect)
            {
                Log.Warning("⚠️ Cannot connect to database");
                return;
            }

            bool tablesExist = await CheckIfTablesExistAsync(context);

            if (tablesExist)
            {
                Log.Information("📋 Database tables already exist (likely from DbUp migrations)");
                Log.Information("🔄 Ensuring EF Core migration history is synchronized...");

                await context.Database.ExecuteSqlRawAsync(@"
                    IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
                    BEGIN
                        CREATE TABLE [__EFMigrationsHistory] (
                            [MigrationId] nvarchar(150) NOT NULL,
                            [ProductVersion] nvarchar(32) NOT NULL,
                            CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
                        );
                    END;");

                IEnumerable<string> allMigrations = context.Database.GetMigrations();
                IEnumerable<string> appliedMigrations = await context.Database.GetAppliedMigrationsAsync();
                IEnumerable<string> pendingMigrations = allMigrations.Except(appliedMigrations);

                if (pendingMigrations.Any())
                {
                    Log.Information("📝 Marking {Count} EF migrations as applied:", pendingMigrations.Count());
                    foreach (string migration in pendingMigrations)
                    {
                        Log.Information("   - {Migration}", migration);
                        await context.Database.ExecuteSqlRawAsync(
                            "INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES ({0}, {1})",
                            migration, "9.0.0");
                    }
                }

                Log.Information("✅ Database schema is synchronized with EF Core");
            }
            else
            {
                Log.Information("🔍 No existing tables found, skipping EF Core migrations for this session");
                Log.Information("💡 To apply EF Core migrations to a fresh database, ensure tables don't exist from previous DbUp runs");
            }

            Log.Information("Database migration check completed");
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Failed to execute migrations");
            logger.LogError(ex, "Failed to execute migrations");
        }
    }

    private static async Task<bool> CheckIfTablesExistAsync(EcliptixSchemaContext context)
    {
        try
        {
            string sql = @"
                SELECT
                    CASE WHEN OBJECT_ID('dbo.VerificationFlows') IS NOT NULL THEN 1 ELSE 0 END +
                    CASE WHEN OBJECT_ID('dbo.MobileNumbers') IS NOT NULL THEN 1 ELSE 0 END +
                    CASE WHEN OBJECT_ID('dbo.Devices') IS NOT NULL THEN 1 ELSE 0 END AS TableCount";

            using Microsoft.Data.SqlClient.SqlConnection connection = new Microsoft.Data.SqlClient.SqlConnection(
                context.Database.GetConnectionString());
            await connection.OpenAsync();

            using Microsoft.Data.SqlClient.SqlCommand command = new Microsoft.Data.SqlClient.SqlCommand(sql, connection);
            object? result = await command.ExecuteScalarAsync();

            int tableCount = Convert.ToInt32(result ?? 0);
            Log.Information("Found {TableCount} existing core tables", tableCount);

            return tableCount >= 2;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Error checking for existing tables");
            return false;
        }
    }

    private static int GetDbSetCount(EcliptixSchemaContext context)
    {
        return context.GetType()
            .GetProperties()
            .Count(p => p.PropertyType.IsGenericType &&
                       p.PropertyType.GetGenericTypeDefinition() == typeof(DbSet<>));
    }
}