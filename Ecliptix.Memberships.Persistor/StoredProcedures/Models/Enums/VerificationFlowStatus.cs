namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

public enum VerificationFlowStatus
{
    Pending,
    Verified,
    Failed,
    Expired,
    MaxAttemptsReached
}