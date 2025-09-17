using Microsoft.Data.SqlClient;
using EcliptixPersistorMigrator.StoredProcedures.Models;

namespace EcliptixPersistorMigrator.StoredProcedures.Interfaces;

public interface IStoredProcedureExecutor
{
    Task<StoredProcedureResult<T>> ExecuteAsync<T>(
        string procedureName,
        SqlParameter[] parameters,
        Func<SqlDataReader, T> dataMapper,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<T>> ExecuteWithOutputAsync<T>(
        string procedureName,
        SqlParameter[] parameters,
        Func<SqlParameter[], T> outputMapper,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<object>> ExecuteNonQueryAsync(
        string procedureName,
        SqlParameter[] parameters,
        CancellationToken cancellationToken = default);
}