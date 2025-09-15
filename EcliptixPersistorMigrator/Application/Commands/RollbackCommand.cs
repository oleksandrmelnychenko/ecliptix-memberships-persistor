using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class RollbackCommand : BaseCommand<RollbackOptions>
{
    public RollbackCommand(ILogger<RollbackCommand> logger) : base(logger) { }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        Logger.LogWarning("Rollback functionality is not implemented yet");
        Console.WriteLine($"⚠️  Rollback functionality is not implemented yet");
        Console.WriteLine($"Target version: {Options.TargetVersion}");
        
        await Task.CompletedTask;
        return CommandResult.Success("Rollback placeholder executed");
    }
}