using System.Data;
using EcliptixPersistorMigrator.Core.Interfaces;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace EcliptixPersistorMigrator.Infrastructure.Database;

public sealed class DatabaseConnection : IDatabaseConnection
{
    private readonly string _connectionString;
    private readonly ILogger<DatabaseConnection> _logger;

    public DatabaseConnection(string connectionString, ILogger<DatabaseConnection> logger)
    {
        _connectionString = connectionString ?? throw new ArgumentNullException(nameof(connectionString));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<bool> TestConnectionAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            using SqlConnection connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);
            _logger.LogDebug("Database connection test successful");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database connection test failed");
            return false;
        }
    }

    public async Task<T> ExecuteAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(operation);

        try
        {
            _logger.LogDebug("Executing database operation");
            T result = await operation();
            _logger.LogDebug("Database operation completed successfully");
            return result;
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "SQL exception during database operation: {Message}", ex.Message);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected exception during database operation");
            throw;
        }
    }

    public async Task ExecuteAsync(Func<Task> operation, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(operation);

        try
        {
            _logger.LogDebug("Executing database operation");
            await operation();
            _logger.LogDebug("Database operation completed successfully");
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "SQL exception during database operation: {Message}", ex.Message);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected exception during database operation");
            throw;
        }
    }

    public async Task<T> ExecuteInTransactionAsync<T>(Func<IDbTransaction, Task<T>> operation,
        IsolationLevel isolationLevel = IsolationLevel.ReadCommitted,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(operation);

        using SqlConnection connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        using SqlTransaction transaction = connection.BeginTransaction(isolationLevel);

        try
        {
            _logger.LogDebug("Executing database operation in transaction");
            T result = await operation(transaction);
            transaction.Commit();
            _logger.LogDebug("Database transaction committed successfully");
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database transaction failed, rolling back");
            transaction.Rollback();
            throw;
        }
    }

    public async Task ExecuteInTransactionAsync(Func<IDbTransaction, Task> operation,
        IsolationLevel isolationLevel = IsolationLevel.ReadCommitted,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(operation);

        using SqlConnection connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);

        using SqlTransaction transaction = connection.BeginTransaction(isolationLevel);

        try
        {
            _logger.LogDebug("Executing database operation in transaction");
            await operation(transaction);
            transaction.Commit();
            _logger.LogDebug("Database transaction committed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database transaction failed, rolling back");
            transaction.Rollback();
            throw;
        }
    }
}