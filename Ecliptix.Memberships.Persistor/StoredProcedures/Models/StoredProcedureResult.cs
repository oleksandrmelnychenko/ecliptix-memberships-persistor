using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Models;

public class StoredProcedureResult<T>
{
    public bool IsSuccess { get; set; }
    public ProcedureOutcome Outcome { get; set; }
    public string? ErrorMessage { get; set; }
    public T? Data { get; set; }
    public DateTime ExecutedAt { get; set; } = DateTime.UtcNow;

    public static StoredProcedureResult<T> Success(T data) =>
        new()
        {
            IsSuccess = true,
            Outcome = ProcedureOutcome.Success,
            Data = data
        };

    public static StoredProcedureResult<T> Failure(ProcedureOutcome outcome, string? errorMessage = null) =>
        new()
        {
            IsSuccess = false,
            Outcome = outcome,
            ErrorMessage = errorMessage
        };
}

public record PhoneNumberData
{
    public long PhoneNumberId { get; init; }
    public Guid UniqueId { get; init; }
    public bool IsNewlyCreated { get; init; }
}

public record DeviceRegistrationData
{
    public long DeviceRecordId { get; init; }
    public Guid DeviceUniqueId { get; init; }
    public bool IsNewlyCreated { get; init; }
}

public record VerificationFlowData
{
    public Guid FlowUniqueId { get; init; }
    public DateTime? ExpiresAt { get; init; }
}

public record OtpGenerationData
{
    public string OtpCode { get; init; } = string.Empty;
    public Guid OtpUniqueId { get; init; }
    public DateTime ExpiresAt { get; init; }
}

public record OtpVerificationData
{
    public bool IsValid { get; init; }
    public DateTime? VerifiedAt { get; init; }
    public int RemainingAttempts { get; init; }
}

public record RequestResendOtpData
{
    public string Outcome { get; init; } = string.Empty;
}

public record MembershipQueryData
{
    public required Guid UniqueIdentifier { get; init; }
    public required MembershipActivityStatus ActivityStatus { get; init; }
    public MembershipCreationStatus CreationStatus { get; init; }
    public byte[] SecureKey { get; init; } = [];
}
