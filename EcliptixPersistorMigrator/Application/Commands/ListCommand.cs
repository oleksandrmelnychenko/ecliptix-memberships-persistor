using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class ListCommand : BaseCommand<ListOptions>
{
    public ListCommand(ILogger<ListCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogInformation("ListCommand functionality will be implemented");
        Console.WriteLine("⚠️ ListCommand functionality will be implemented");
        
        await Task.CompletedTask;
        return CommandResult.Success("ListCommand placeholder executed");
    }
}
