namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    
    
    NoData,
    SqlError,
    AlreadyExists,
    RateLimitExceeded,
    MembershipAlreadyExists,
    Error,
    Invalid
}