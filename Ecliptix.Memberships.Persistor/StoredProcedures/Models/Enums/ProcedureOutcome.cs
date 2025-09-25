namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    Updated,
    Verified,

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
    PhoneNotFound,
    RateLimitExceeded,
    SqlError
}