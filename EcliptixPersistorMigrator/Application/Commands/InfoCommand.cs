using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class InfoCommand : BaseCommand<object>
{
    public InfoCommand(ILogger<InfoCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("InfoCommand functionality will be implemented");
        Console.WriteLine("⚠️ InfoCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("InfoCommand placeholder executed");
    }
}
