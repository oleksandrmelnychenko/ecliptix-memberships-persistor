namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    Updated,
    Verified,

    AlreadyExists,
    Error,
    FlowExpired,
    Invalid,
    InvalidCode,
    MaxAttemptsExceeded,
    MembershipAlreadyExists,
    NoActiveOtp,
    NoData,
    RateLimitExceeded,
    SqlError
}