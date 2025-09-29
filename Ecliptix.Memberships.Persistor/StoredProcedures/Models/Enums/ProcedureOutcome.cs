namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum ProcedureOutcome
{
    Success,
    Updated,
    Verified,
    Found,

    AlreadyExists,
    ActiveFlowExists,
    DeviceNotFound,
    DeviceRateLimitExceeded,
    Error,
    EligibleForRecovery,
    FlowExpired,
    FlowNotFound,
    Invalid,
    InvalidCode,
    MembershipNotFound,
    MaxAttemptsExceeded,
    MembershipBlocked,
    MembershipAlreadyExists,
    NoData,
    NoActiveOtp,
    NoSecureKey,
    OtpLimitExceeded,
    MobileNotFound,
    RateLimitExceeded,
    SqlError
}