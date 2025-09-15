using EcliptixPersistorMigrator.Core.Enums;
using EcliptixPersistorMigrator.Core.Interfaces;
using EcliptixPersistorMigrator.Application.Commands;
using Microsoft.Extensions.DependencyInjection;

namespace EcliptixPersistorMigrator.Core.Commands;

public sealed class CommandFactory
{
    private readonly IServiceProvider _serviceProvider;

    public CommandFactory(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public ICommand CreateCommand<TOptions>(CommandType commandType, TOptions options)
    {
        return commandType switch
        {
            CommandType.Migrate => _serviceProvider.GetRequiredService<MigrateCommand>(),
            CommandType.Status => _serviceProvider.GetRequiredService<StatusCommand>(),
            CommandType.Test => _serviceProvider.GetRequiredService<TestCommand>(),
            _ => throw new ArgumentOutOfRangeException(nameof(commandType), commandType, "Unknown command type")
        };
    }

    public static CommandType ParseCommandType(string command)
    {
        return command.ToLowerInvariant() switch
        {
            "migrate" => CommandType.Migrate,
            "status" => CommandType.Status,
            "test" => CommandType.Test,
            _ => throw new ArgumentException($"Unknown command: {command}", nameof(command))
        };
    }
}