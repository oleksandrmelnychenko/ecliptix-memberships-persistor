using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class MarkCommand : BaseCommand<object>
{
    public MarkCommand(ILogger<MarkCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("MarkCommand functionality will be implemented");
        Console.WriteLine("⚠️ MarkCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("MarkCommand placeholder executed");
    }
}
