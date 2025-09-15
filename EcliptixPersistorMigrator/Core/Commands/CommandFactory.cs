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
            CommandType.Rollback => _serviceProvider.GetRequiredService<RollbackCommand>(),
            CommandType.Seed => _serviceProvider.GetRequiredService<SeedCommand>(),
            CommandType.Validate => _serviceProvider.GetRequiredService<ValidateCommand>(),
            CommandType.Repair => _serviceProvider.GetRequiredService<RepairCommand>(),
            CommandType.List => _serviceProvider.GetRequiredService<ListCommand>(),
            CommandType.Info => _serviceProvider.GetRequiredService<InfoCommand>(),
            CommandType.Reset => _serviceProvider.GetRequiredService<ResetCommand>(),
            CommandType.Backup => _serviceProvider.GetRequiredService<BackupCommand>(),
            CommandType.Restore => _serviceProvider.GetRequiredService<RestoreCommand>(),
            CommandType.Test => _serviceProvider.GetRequiredService<TestCommand>(),
            CommandType.History => _serviceProvider.GetRequiredService<HistoryCommand>(),
            CommandType.Pending => _serviceProvider.GetRequiredService<PendingCommand>(),
            CommandType.Mark => _serviceProvider.GetRequiredService<MarkCommand>(),
            CommandType.Generate => _serviceProvider.GetRequiredService<GenerateCommand>(),
            CommandType.Diff => _serviceProvider.GetRequiredService<DiffCommand>(),
            CommandType.Export => _serviceProvider.GetRequiredService<ExportCommand>(),
            _ => throw new ArgumentOutOfRangeException(nameof(commandType), commandType, "Unknown command type")
        };
    }

    public static CommandType ParseCommandType(string command)
    {
        return command.ToLowerInvariant() switch
        {
            "migrate" => CommandType.Migrate,
            "status" => CommandType.Status,
            "rollback" => CommandType.Rollback,
            "seed" => CommandType.Seed,
            "validate" => CommandType.Validate,
            "repair" => CommandType.Repair,
            "list" => CommandType.List,
            "info" => CommandType.Info,
            "reset" => CommandType.Reset,
            "backup" => CommandType.Backup,
            "restore" => CommandType.Restore,
            "test" => CommandType.Test,
            "history" => CommandType.History,
            "pending" => CommandType.Pending,
            "mark" => CommandType.Mark,
            "generate" => CommandType.Generate,
            "diff" => CommandType.Diff,
            "export" => CommandType.Export,
            _ => throw new ArgumentException($"Unknown command: {command}", nameof(command))
        };
    }
}