using Ecliptix.Memberships.Persistor.StoredProcedures.Models;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;

public interface IVerificationService
{
    Task<StoredProcedureResult<MobileNumberData>> EnsureMobileNumberAsync(
        string mobileNumber,
        string? region = null,
        CancellationToken cancellationToken = default);
    
    Task<StoredProcedureResult<VerificationFlowData>> InitiateVerificationFlowAsync(
        string mobileNumber,
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

    Task<StoredProcedureResult<RequestResendOtpData>> RequestResendOtpCodeAsync(
        Guid flowUniqueId,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<UpdateVerificationFlowStatusData>> UpdateVerificationFlowStatusAsync(
        Guid flowUniqueId,
        Models.Enums.VerificationFlowStatus status,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<VerifyMobileForSecretKeyRecoveryData>> VerifyMobileForSecretKeyRecoveryAsync(
        string mobileNumber,
        string? region,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<GetMobileNumberData>> GetMobileNumberAsync(
        Guid phoneNumberIdentifier,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<Guid>> UpdateOtpStatusAsync(
        Guid otpUniqueId,
        Models.Enums.VerificationFlowStatus status,
        CancellationToken cancellationToken = default);

    Task<StoredProcedureResult<ExpireAssociatedOtpData>> ExpireAssociatedOtpAsync(
        Guid flowUniqueId,
        CancellationToken cancellationToken = default);
}