using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class ResetCommand : BaseCommand<object>
{
    public ResetCommand(ILogger<ResetCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("ResetCommand functionality will be implemented");
        Console.WriteLine("⚠️ ResetCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("ResetCommand placeholder executed");
    }
}
