using EcliptixPersistorMigrator.Core.Domain;

namespace EcliptixPersistorMigrator.Core.Interfaces;

public interface ICommand
{
    Task<CommandResult> ExecuteAsync(CancellationToken cancellationToken = default);
}

public interface ICommand<TOptions> : ICommand
{
    TOptions Options { get; }
}