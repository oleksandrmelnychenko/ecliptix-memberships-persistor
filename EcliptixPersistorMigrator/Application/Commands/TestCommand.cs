using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Commands;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Interfaces;
using EcliptixPersistorMigrator.Presentation.Cli;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Application.Commands;

public sealed class TestCommand : BaseCommand<TestOptions>
{
    private readonly IDatabaseConnection _databaseConnection;

    public TestCommand(
        IDatabaseConnection databaseConnection,
        ILogger<TestCommand> logger)
        : base(logger)
    {
        _databaseConnection = databaseConnection ?? throw new ArgumentNullException(nameof(databaseConnection));
    }

    protected override async Task<CommandResult> ExecuteInternalAsync(CancellationToken cancellationToken)
    {
        ValidateOptions();

        Logger.LogInformation("Testing database connection...");

        try
        {
            bool isConnectionSuccessful = await _databaseConnection.TestConnectionAsync(cancellationToken);

            if (isConnectionSuccessful)
            {
                string successMessage = "✅ Database connection test successful";
                Logger.LogInformation(successMessage);
                Console.WriteLine(successMessage);
                return CommandResult.Success(successMessage);
            }
            else
            {
                string failureMessage = "❌ Database connection test failed";
                Logger.LogError(failureMessage);
                Console.WriteLine(failureMessage);
                return CommandResult.Failure(failureMessage, exitCode: Constants.ExitCodes.DatabaseConnectionError);
            }
        }
        catch (Exception ex)
        {
            string errorMessage = $"❌ Database connection test failed: {ex.Message}";
            Logger.LogError(ex, "Database connection test failed");
            Console.WriteLine(errorMessage);
            return CommandResult.Failure(errorMessage, ex, Constants.ExitCodes.DatabaseConnectionError);
        }
    }
}