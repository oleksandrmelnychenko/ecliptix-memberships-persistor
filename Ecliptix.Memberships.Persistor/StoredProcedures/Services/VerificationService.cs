using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using System.Data;
using Ecliptix.Memberships.Persistor.StoredProcedures.Helpers;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Services;

public class VerificationService : IVerificationService
{
    private readonly IStoredProcedureExecutor _executor;
    private readonly ILogger<VerificationService> _logger;

    public VerificationService(IStoredProcedureExecutor executor, ILogger<VerificationService> logger)
    {
        _executor = executor;
        _logger = logger;
    }

    public async Task<StoredProcedureResult<PhoneNumberData>> EnsureMobileNumberAsync(
        string phoneNumber,
        string? region = null,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Ensuring phone number exists: {PhoneNumber}", phoneNumber);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@PhoneNumber", phoneNumber),
            SqlParameterHelper.In("@Region", region),
            SqlParameterHelper.Out("@PhoneNumberId", SqlDbType.BigInt),
            SqlParameterHelper.Out("@UniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@IsNewlyCreated", SqlDbType.Bit)
        ];

        return await _executor.ExecuteWithOutputAsync(
            "dbo.SP_EnsureMobileNumber",
            parameters,
            outputParams => new PhoneNumberData(
                PhoneNumberId: (long)outputParams[2].Value,
                UniqueId: (Guid)outputParams[3].Value,
                IsNewlyCreated: (bool)outputParams[4].Value
            ),
            cancellationToken);
    }

    public async Task<StoredProcedureResult<VerificationFlowData>> InitiateVerificationFlowAsync(
        string phoneNumber,
        string region,
        Guid appDeviceId,
        string purpose = "unspecified",
        long? connectionId = null,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Initiating verification flow for phone: {PhoneNumber}", phoneNumber);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@PhoneNumber", phoneNumber),
            SqlParameterHelper.In("@Region", region),
            SqlParameterHelper.In("@AppDeviceId", appDeviceId),
            SqlParameterHelper.In("@Purpose", purpose),
            SqlParameterHelper.In("@ConnectionId", connectionId ?? (object)DBNull.Value),
            SqlParameterHelper.Out("@FlowUniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, 50),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, 500)
        ];

        StoredProcedureResult<VerificationFlowData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.SP_InitiateVerificationFlow",
            parameters,
            outputParams =>
            {
                string outcome = outputParams[6].Value?.ToString() ?? "error";
                string? errorMessage = outputParams[7].Value?.ToString();
                Guid flowId = outputParams[5].Value != DBNull.Value ? (Guid)outputParams[5].Value : Guid.Empty;

                if (outcome == "success")
                {
                    return new VerificationFlowData(
                        FlowUniqueId: flowId,
                        ExpiresAt: DateTime.UtcNow.AddMinutes(15)
                    );
                }

                throw new InvalidOperationException($"Failed to initiate verification flow: {outcome} - {errorMessage}");
            },
            cancellationToken);

        if (!result.IsSuccess && result.ErrorMessage?.Contains("Failed to initiate verification flow") == true)
        {
            string[] parts = result.ErrorMessage.Split(" - ", 2);
            if (parts.Length == 2)
            {
                return StoredProcedureResult<VerificationFlowData>.Failure(parts[0].Split(": ")[1], parts[1]);
            }
        }

        return result;
    }

    public async Task<StoredProcedureResult<OtpGenerationData>> GenerateOtpCodeAsync(
        Guid flowUniqueId,
        int otpLength = 6,
        int expiryMinutes = 5,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Generating OTP code for flow: {FlowId}", flowUniqueId);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@FlowUniqueId", flowUniqueId),
            SqlParameterHelper.In("@OtpLength", otpLength),
            SqlParameterHelper.In("@ExpiryMinutes", expiryMinutes),
            SqlParameterHelper.Out("@OtpCode", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@OtpUniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, 50),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, 500)
        ];

        StoredProcedureResult<OtpGenerationData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.SP_GenerateOtpCode",
            parameters,
            outputParams =>
            {
                string outcome = outputParams[5].Value?.ToString() ?? "error";
                string? errorMessage = outputParams[6].Value?.ToString();

                if (outcome == "success")
                {
                    return new OtpGenerationData(
                        OtpCode: outputParams[3].Value?.ToString() ?? "",
                        OtpUniqueId: (Guid)outputParams[4].Value,
                        ExpiresAt: DateTime.UtcNow.AddMinutes(expiryMinutes)
                    );
                }

                throw new InvalidOperationException($"Failed to generate OTP: {outcome} - {errorMessage}");
            },
            cancellationToken);

        if (!result.IsSuccess && result.ErrorMessage?.Contains("Failed to generate OTP") == true)
        {
            string[] parts = result.ErrorMessage.Split(" - ", 2);
            if (parts.Length == 2)
            {
                return StoredProcedureResult<OtpGenerationData>.Failure(parts[0].Split(": ")[1], parts[1]);
            }
        }

        return result;
    }
    
    public async Task<StoredProcedureResult<OtpVerificationData>> VerifyOtpCodeAsync(
        Guid flowUniqueId,
        string otpCode,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Verifying OTP code for flow: {FlowId}", flowUniqueId);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@FlowUniqueId", flowUniqueId),
            SqlParameterHelper.In("@OtpCode", otpCode),
            SqlParameterHelper.Out("@IsValid", SqlDbType.Bit),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, 50),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, 500),
            SqlParameterHelper.Out("@VerifiedAt", SqlDbType.DateTime2)
        ];

        StoredProcedureResult<OtpVerificationData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.SP_VerifyOtpCode",
            parameters,
            outputParams =>
            {
                bool isValid = (bool)outputParams[2].Value;
                string outcome = outputParams[3].Value?.ToString() ?? "invalid";
                string? errorMessage = outputParams[4].Value?.ToString();
                DateTime? verifiedAt = outputParams[5].Value != DBNull.Value ? (DateTime?)outputParams[7].Value : null;

                return new OtpVerificationData(
                    IsValid: isValid,
                    VerifiedAt: verifiedAt,
                    RemainingAttempts: outcome.Contains("attempts remaining") ?
                        int.Parse(outcome.Split(" ")[0]) : 0
                );
            },
            cancellationToken);

        return result;
    }
}