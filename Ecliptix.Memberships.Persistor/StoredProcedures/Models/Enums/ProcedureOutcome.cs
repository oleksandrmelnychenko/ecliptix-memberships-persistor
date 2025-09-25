namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    Verified,
    
    FlowExpired,
    MaxAttemptsExceeded,
    InvalidCode,
    NoActiveOtp,
    NoData,
    SqlError,
    AlreadyExists,
    RateLimitExceeded,
    MembershipAlreadyExists,
    Error,
    Invalid
}