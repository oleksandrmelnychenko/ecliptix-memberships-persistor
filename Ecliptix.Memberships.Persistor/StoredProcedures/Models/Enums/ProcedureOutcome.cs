namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    Updated,
    Verified,
    Found,

    AlreadyExists,
    Error,
    EligibleForRecovery,
    FlowExpired,
    Invalid,
    InvalidCode,
    MembershipNotFound,
    MaxAttemptsExceeded,
    MembershipBlocked,
    MembershipAlreadyExists,
    NoData,
    NoActiveOtp,
    NoSecureKey,
    MobileNotFound,
    RateLimitExceeded,
    SqlError
}