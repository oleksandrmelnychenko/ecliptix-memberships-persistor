using System.Diagnostics;
using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Enums;
using EcliptixPersistorMigrator.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Core.Commands;

public abstract class BaseCommand<TOptions> : ICommand<TOptions>
{
    protected readonly ILogger Logger;

    protected BaseCommand(ILogger logger)
    {
        Logger = logger;
    }

    public required TOptions Options { get; set; }

    public async Task<CommandResult> ExecuteAsync(CancellationToken cancellationToken = default)
    {
        Stopwatch stopwatch = Stopwatch.StartNew();

        try
        {
            Logger.LogInformation("Starting command execution: {CommandType}", GetType().Name);

            CommandResult result = await ExecuteInternalAsync(cancellationToken);

            stopwatch.Stop();
            CommandResult finalResult = result with { ExecutionTime = stopwatch.Elapsed };

            if (finalResult.IsSuccess)
            {
                Logger.LogInformation("Command completed successfully in {ElapsedTime}ms",
                    stopwatch.ElapsedMilliseconds);
            }
            else
            {
                Logger.LogError("Command failed: {Message}", finalResult.Message);
                if (finalResult.Exception != null)
                {
                    Logger.LogError(finalResult.Exception, "Command execution exception");
                }
            }

            return finalResult;
        }
        catch (OperationCanceledException)
        {
            stopwatch.Stop();
            Logger.LogWarning("Command execution was cancelled");
            return CommandResult.Success("Operation cancelled", Constants.Numeric.Zero) with { ExecutionTime = stopwatch.Elapsed };
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            Logger.LogError(ex, "Unexpected error during command execution");
            return CommandResult.Failure("Unexpected error occurred", ex) with { ExecutionTime = stopwatch.Elapsed };
        }
    }

    protected abstract Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken);

    protected virtual void ValidateOptions()
    {
        if (Options == null)
        {
            throw new ArgumentNullException(nameof(Options), "Command options cannot be null");
        }
    }
}