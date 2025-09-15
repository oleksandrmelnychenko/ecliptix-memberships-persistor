using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class PendingCommand : BaseCommand<object>
{
    public PendingCommand(ILogger<PendingCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("PendingCommand functionality will be implemented");
        Console.WriteLine("⚠️ PendingCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("PendingCommand placeholder executed");
    }
}
