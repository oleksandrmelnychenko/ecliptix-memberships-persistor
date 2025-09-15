using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class RestoreCommand : BaseCommand<RestoreOptions>
{
    public RestoreCommand(ILogger<RestoreCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("RestoreCommand functionality will be implemented");
        Console.WriteLine("⚠️ RestoreCommand functionality will be implemented");

        await Task.CompletedTask;
        return CommandResult.Success("RestoreCommand placeholder executed");
    }
}
