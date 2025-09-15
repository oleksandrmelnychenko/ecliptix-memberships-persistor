using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class DiffCommand : BaseCommand<object>
{
    public DiffCommand(ILogger<DiffCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("DiffCommand functionality will be implemented");
        Console.WriteLine("⚠️ DiffCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("DiffCommand placeholder executed");
    }
}
