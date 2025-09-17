namespace EcliptixPersistorMigrator.StoredProcedures.Models;

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

public class PhoneNumberData
{
    public long PhoneNumberId { get; set; }
    public Guid UniqueId { get; set; }
    public bool IsNewlyCreated { get; set; }
}

public class DeviceRegistrationData
{
    public long DeviceRecordId { get; set; }
    public Guid DeviceUniqueId { get; set; }
    public bool IsNewlyCreated { get; set; }
}

public class VerificationFlowData
{
    public Guid FlowUniqueId { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

public class OtpGenerationData
{
    public string OtpCode { get; set; } = string.Empty;
    public Guid OtpUniqueId { get; set; }
    public DateTime ExpiresAt { get; set; }
}

public class OtpVerificationData
{
    public bool IsValid { get; set; }
    public DateTime? VerifiedAt { get; set; }
    public int RemainingAttempts { get; set; }
}