using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;
using Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Services;

public class StoredProcedureExecutor : IStoredProcedureExecutor
{
    private readonly string _connectionString;
    private readonly ILogger<StoredProcedureExecutor> _logger;

    public StoredProcedureExecutor(IConfiguration configuration, ILogger<StoredProcedureExecutor> logger)
    {
        _connectionString = configuration.GetConnectionString("EcliptixMemberships")
            ?? throw new InvalidOperationException("Connection string 'EcliptixMemberships' not found");
        _logger = logger;
    }

    public async Task<StoredProcedureResult<T>> ExecuteAsync<T>(
        string procedureName,
        SqlParameter[] parameters,
        Func<SqlDataReader, T> dataMapper,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogDebug("Executing stored procedure: {ProcedureName}", procedureName);

            using SqlConnection connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);

            using SqlCommand command = new SqlCommand(procedureName, connection)
            {
                CommandType = System.Data.CommandType.StoredProcedure,
                CommandTimeout = 30
            };

            if (parameters != null)
            {
                command.Parameters.AddRange(parameters);
            }

            using SqlDataReader reader = await command.ExecuteReaderAsync(cancellationToken);

            if (await reader.ReadAsync(cancellationToken))
            {
                T data = dataMapper(reader);
                return StoredProcedureResult<T>.Success(data);
            }

            return StoredProcedureResult<T>.Failure(ProcedureOutcome.NoData, "No data returned from stored procedure");
        }
        catch (SqlException sqlEx)
        {
            _logger.LogError(sqlEx, "SQL error executing stored procedure {ProcedureName}: {ErrorMessage}",
                procedureName, sqlEx.Message);
            return StoredProcedureResult<T>.Failure(ProcedureOutcome.SqlError, sqlEx.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing stored procedure {ProcedureName}: {ErrorMessage}",
                procedureName, ex.Message);
            return StoredProcedureResult<T>.Failure(ProcedureOutcome.Error, ex.Message);
        }
    }

    public async Task<StoredProcedureResult<T>> ExecuteWithOutputAsync<T>(
        string procedureName,
        SqlParameter[] parameters,
        Func<SqlParameter[], T> outputMapper,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogDebug("Executing stored procedure with output: {ProcedureName}", procedureName);

            using SqlConnection connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);

            using SqlCommand command = new SqlCommand(procedureName, connection)
            {
                CommandType = System.Data.CommandType.StoredProcedure,
                CommandTimeout = 30
            };

            if (parameters != null)
            {
                command.Parameters.AddRange(parameters);
            }

            await command.ExecuteNonQueryAsync(cancellationToken);

            T data = outputMapper(parameters);
            return StoredProcedureResult<T>.Success(data);
        }
        catch (SqlException sqlEx)
        {
            _logger.LogError(sqlEx, "SQL error executing stored procedure {ProcedureName}: {ErrorMessage}",
                procedureName, sqlEx.Message);
            return StoredProcedureResult<T>.Failure(ProcedureOutcome.Error, sqlEx.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing stored procedure {ProcedureName}: {ErrorMessage}",
                procedureName, ex.Message);
            return StoredProcedureResult<T>.Failure(ProcedureOutcome.Error, ex.Message);
        }
    }

    public async Task<StoredProcedureResult<object>> ExecuteNonQueryAsync(
        string procedureName,
        SqlParameter[] parameters,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogDebug("Executing non-query stored procedure: {ProcedureName}", procedureName);

            using SqlConnection connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);

            using SqlCommand command = new SqlCommand(procedureName, connection)
            {
                CommandType = System.Data.CommandType.StoredProcedure,
                CommandTimeout = 30
            };

            if (parameters != null)
            {
                command.Parameters.AddRange(parameters);
            }

            int rowsAffected = await command.ExecuteNonQueryAsync(cancellationToken);

            return StoredProcedureResult<object>.Success(rowsAffected);
        }
        catch (SqlException sqlEx)
        {
            _logger.LogError(sqlEx, "SQL error executing stored procedure {ProcedureName}: {ErrorMessage}",
                procedureName, sqlEx.Message);
            return StoredProcedureResult<object>.Failure(ProcedureOutcome.SqlError, sqlEx.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing stored procedure {ProcedureName}: {ErrorMessage}",
                procedureName, ex.Message);
            return StoredProcedureResult<object>.Failure(ProcedureOutcome.Error, ex.Message);
        }
    }

    public async Task<StoredProcedureResult<T>> ExecuteWithOutcomeAsync<T>(
        string procedureName,
        SqlParameter[] parameters,
        Func<SqlParameter[], T> mapResult,
        short outcomeIndex,
        short errorIndex,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogDebug("Executing stored procedure with outcome: {ProcedureName}", procedureName);

            await using SqlConnection connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            await using SqlCommand command = new SqlCommand(procedureName, connection)
            {
                CommandType = System.Data.CommandType.StoredProcedure,
                CommandTimeout = 30
            };

            if (parameters.Length > 0)
            {
                command.Parameters.AddRange(parameters);
            }

            await command.ExecuteNonQueryAsync(cancellationToken);
            
            string? outcomeRaw = parameters[outcomeIndex].Value?.ToString();
            string? errorMessage = parameters[errorIndex].Value?.ToString();
            ProcedureOutcome outcome = OutcomeParser.Parse(outcomeRaw);

            if (outcome == ProcedureOutcome.Success)
            {
                T data = mapResult(parameters);
                return StoredProcedureResult<T>.Success(data);
            }
            
            return StoredProcedureResult<T>.Failure(outcome, errorMessage);
        }
        catch (SqlException sqlEx)
        {
            _logger.LogError(sqlEx, "SQL error executing stored procedure {ProcedureName}: {ErrorMessage}", procedureName, sqlEx.Message);
            return StoredProcedureResult<T>.Failure(ProcedureOutcome.SqlError, sqlEx.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing stored procedure {ProcedureName}: {ErrorMessage}", procedureName, ex.Message);
            return StoredProcedureResult<T>.Failure(ProcedureOutcome.Error, ex.Message);
        }
    }
}