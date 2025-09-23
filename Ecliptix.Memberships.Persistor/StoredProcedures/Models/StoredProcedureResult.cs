namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models;

public class StoredProcedureResult<T>
{
    public bool IsSuccess { get; set; }
    public string Outcome { get; set; } = string.Empty;
    public string? ErrorMessage { get; set; }
    public T? Data { get; set; }
    public DateTime ExecutedAt { get; set; } = DateTime.UtcNow;

    public static StoredProcedureResult<T> Success(T data, string outcome = "success")
    {
        return new StoredProcedureResult<T>
        {
            IsSuccess = true,
            Outcome = outcome,
            Data = data
        };
    }

    public static StoredProcedureResult<T> Failure(string outcome, string? errorMessage = null)
    {
        return new StoredProcedureResult<T>
        {
            IsSuccess = false,
            Outcome = outcome,
            ErrorMessage = errorMessage
        };
    }
}

public record PhoneNumberData(long PhoneNumberId, Guid UniqueId, bool IsNewlyCreated);
public record DeviceRegistrationData(long DeviceRecordId, Guid DeviceUniqueId, bool IsNewlyCreated);
public record VerificationFlowData(Guid FlowUniqueId, DateTime? ExpiresAt);
public record OtpGenerationData(string OtpCode, Guid OtpUniqueId, DateTime ExpiresAt);
public record OtpVerificationData(bool IsValid, DateTime? VerifiedAt, int RemainingAttempts);
public record CreateMembershipData(Guid MembershipUniqueId, string Status, string CreationStatus);
public record LoginMembershipData(Guid MembershipUniqueId, string Status, byte[]? SecureKey);
