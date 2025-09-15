using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class SeedCommand : BaseCommand<SeedOptions>
{
    public SeedCommand(ILogger<SeedCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("Starting seed data deployment...");

        if (Options.DryRun)
        {
            Console.WriteLine("🔍 DRY RUN MODE - No changes will be made");
        }

        Console.WriteLine("🌱 Seed functionality will be implemented");

        await Task.CompletedTask;
        return CommandResult.Success("Seed placeholder executed");
    }
}