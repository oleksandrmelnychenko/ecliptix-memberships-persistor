using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class HistoryCommand : BaseCommand<object>
{
    public HistoryCommand(ILogger<HistoryCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("HistoryCommand functionality will be implemented");
        Console.WriteLine("⚠️ HistoryCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("HistoryCommand placeholder executed");
    }
}
