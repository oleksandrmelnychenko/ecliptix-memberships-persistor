using System.Text.Json;
using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Interfaces;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class StatusCommand : BaseCommand<StatusOptions>
{
    private readonly IMigrationRepository _migrationRepository;

    public StatusCommand(
        IMigrationRepository migrationRepository,
        ILogger<StatusCommand> logger)
        : base(logger)
    {
        _migrationRepository = migrationRepository ?? throw new ArgumentNullException(nameof(migrationRepository));
    }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        ValidateOptions();

        Logger.LogInformation("Retrieving database migration status...");

        IEnumerable<Migration> executedMigrations = await _migrationRepository.GetExecutedMigrationsAsync(cancellationToken);
        IEnumerable<Migration> pendingMigrations = await _migrationRepository.GetPendingMigrationsAsync(cancellationToken);

        List<Migration> executedList = executedMigrations.ToList();
        List<Migration> pendingList = pendingMigrations.ToList();

        object statusData = new
        {
            DatabaseStatus = pendingList.Any() ? "Pending Migrations" : "Up to Date",
            ExecutedMigrations = executedList.Count,
            PendingMigrations = pendingList.Count,
            TotalMigrations = executedList.Count + pendingList.Count,
            ExecutedMigrationDetails = executedList.Select(m => new
            {
                m.FileName,
                m.Version,
                m.Description,
                m.ExecutedAt,
                m.ExecutionTime
            }).ToList(),
            PendingMigrationDetails = pendingList.Select(m => new
            {
                m.FileName,
                m.Version,
                m.Description
            }).ToList()
        };

        if (Options.JsonOutput)
        {
            return await HandleJsonOutputAsync(statusData, cancellationToken);
        }

        return await HandleConsoleOutputAsync(statusData, executedList, pendingList, cancellationToken);
    }

    private async Task<CommandResult> HandleJsonOutputAsync(object statusData, CancellationToken cancellationToken)
    {
        try
        {
            JsonSerializerOptions jsonOptions = new JsonSerializerOptions
            {
                WriteIndented = true,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };

            string json = JsonSerializer.Serialize(statusData, jsonOptions);
            Console.WriteLine(json);

            await Task.CompletedTask;
            return CommandResult.Success("Status retrieved successfully",
                data: new Dictionary<string, object> { { "Json", json } });
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to serialize status to JSON");
            return CommandResult.Failure("Failed to generate JSON output", ex);
        }
    }

    private async Task<CommandResult> HandleConsoleOutputAsync(object statusData,
        List<Migration> executedList, List<Migration> pendingList, CancellationToken cancellationToken)
    {
        Console.WriteLine("📊 Database Migration Status");
        Console.WriteLine("═══════════════════════════");
        Console.WriteLine();

        string statusText = pendingList.Any() ? "⏳ Pending Migrations" : "✅ Up to Date";
        Console.WriteLine($"Status: {statusText}");
        Console.WriteLine($"Executed migrations: {executedList.Count}");
        Console.WriteLine($"Pending migrations: {pendingList.Count}");
        Console.WriteLine($"Total migrations: {executedList.Count + pendingList.Count}");
        Console.WriteLine();

        if (executedList.Any())
        {
            Console.WriteLine("✅ Executed Migrations:");
            foreach (var migration in executedList.OrderBy(m => m.Version))
            {
                string executionInfo = migration.ExecutedAt.HasValue
                    ? $" (executed {migration.ExecutedAt:yyyy-MM-dd HH:mm:ss})"
                    : "";
                Console.WriteLine($"  ✓ {migration.FileName}{executionInfo}");

                if (Options.Verbose && !string.IsNullOrWhiteSpace(migration.Description))
                {
                    Console.WriteLine($"    {migration.Description}");
                }
            }
            Console.WriteLine();
        }

        if (pendingList.Any())
        {
            Console.WriteLine("⏳ Pending Migrations:");
            foreach (var migration in pendingList.OrderBy(m => m.Version))
            {
                Console.WriteLine($"  ⏳ {migration.FileName}");

                if (Options.Verbose && !string.IsNullOrWhiteSpace(migration.Description))
                {
                    Console.WriteLine($"    {migration.Description}");
                }
            }
            Console.WriteLine();
        }
        else
        {
            Console.WriteLine("✅ Database is up to date - no pending migrations");
            Console.WriteLine();
        }

        await Task.CompletedTask;
        return CommandResult.Success("Status displayed successfully",
            data: new Dictionary<string, object>
            {
                { "ExecutedCount", executedList.Count },
                { "PendingCount", pendingList.Count },
                { "TotalCount", executedList.Count + pendingList.Count },
                { "IsUpToDate", !pendingList.Any() }
            });
    }
}