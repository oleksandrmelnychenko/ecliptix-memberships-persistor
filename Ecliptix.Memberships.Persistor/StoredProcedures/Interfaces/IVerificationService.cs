using Ecliptix.Memberships.Persistor.StoredProcedures.Models;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;

public interface IVerificationService
{
    Task<StoredProcedureResult<PhoneNumberData>> EnsurePhoneNumberAsync(
        string phoneNumber,
        string? region = null,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<DeviceRegistrationData>> RegisterAppDeviceAsync(
        Guid appInstanceId,
        Guid deviceId,
        int deviceType = 1,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<VerificationFlowData>> InitiateVerificationFlowAsync(
        string phoneNumber,
        string region,
        Guid appDeviceId,
        string purpose = "unspecified",
        long? connectionId = null,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<OtpGenerationData>> GenerateOtpCodeAsync(
        Guid flowUniqueId,
        int otpLength = 6,
        int expiryMinutes = 5,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<OtpVerificationData>> VerifyOtpCodeAsync(
        Guid flowUniqueId,
        string otpCode,
        CancellationToken cancellationToken = default);
}