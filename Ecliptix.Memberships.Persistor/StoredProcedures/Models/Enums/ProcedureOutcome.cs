namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    
    
    NoData,
    SqlError,
    AlreadyExists,
    Error,
    Invalid
}