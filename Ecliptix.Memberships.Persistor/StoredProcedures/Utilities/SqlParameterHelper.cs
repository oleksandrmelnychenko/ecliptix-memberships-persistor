using System.Data;
using Microsoft.Data.SqlClient;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;

public static class SqlParameterHelper
{
    public static SqlParameter In(string name, object? value) =>
        new(name, value ?? DBNull.Value);

    public static SqlParameter Out(string name, SqlDbType type, int size = 0) =>
        size > 0
            ? new(name, type, size) { Direction = ParameterDirection.Output }
            : new(name, type) { Direction = ParameterDirection.Output };
    
    public static SqlParameter Return(string name, SqlDbType type) =>
        new(name, type) { Direction = ParameterDirection.ReturnValue };
}