using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using EcliptixPersistorMigrator.StoredProcedures.Interfaces;
using EcliptixPersistorMigrator.StoredProcedures.Models;
using System.Data;

namespace EcliptixPersistorMigrator.StoredProcedures.Services;

public class VerificationService : IVerificationService
{
    private readonly IStoredProcedureExecutor _executor;
    private readonly ILogger<VerificationService> _logger;

    public VerificationService(IStoredProcedureExecutor executor, ILogger<VerificationService> logger)
    {
        _executor = executor;
        _logger = logger;
    }

    public async Task<StoredProcedureResult<PhoneNumberData>> EnsurePhoneNumberAsync(
        string phoneNumber,
        string? region = null,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Ensuring phone number exists: {PhoneNumber}", phoneNumber);

        SqlParameter[] parameters = new[]
        {
            new SqlParameter("@PhoneNumber", phoneNumber),
            new SqlParameter("@Region", region ?? (object)DBNull.Value),
            new SqlParameter("@PhoneNumberId", SqlDbType.BigInt) { Direction = ParameterDirection.Output },
            new SqlParameter("@UniqueId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output },
            new SqlParameter("@IsNewlyCreated", SqlDbType.Bit) { Direction = ParameterDirection.Output }
        };

        return await _executor.ExecuteWithOutputAsync(
            "dbo.SP_EnsurePhoneNumber",
            parameters,
            outputParams => new PhoneNumberData
            {
                PhoneNumberId = (long)outputParams[2].Value,
                UniqueId = (Guid)outputParams[3].Value,
                IsNewlyCreated = (bool)outputParams[4].Value
            },
            cancellationToken);
    }

    public async Task<StoredProcedureResult<DeviceRegistrationData>> RegisterAppDeviceAsync(
        Guid appInstanceId,
        Guid deviceId,
        int deviceType = 1,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Registering app device: {DeviceId}", deviceId);

        SqlParameter[] parameters = new[]
        {
            new SqlParameter("@AppInstanceId", appInstanceId),
            new SqlParameter("@DeviceId", deviceId),
            new SqlParameter("@DeviceType", deviceType),
            new SqlParameter("@DeviceUniqueId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output },
            new SqlParameter("@DeviceRecordId", SqlDbType.BigInt) { Direction = ParameterDirection.Output },
            new SqlParameter("@IsNewlyCreated", SqlDbType.Bit) { Direction = ParameterDirection.Output }
        };

        return await _executor.ExecuteWithOutputAsync(
            "dbo.SP_RegisterAppDevice",
            parameters,
            outputParams => new DeviceRegistrationData
            {
                DeviceUniqueId = (Guid)outputParams[3].Value,
                DeviceRecordId = (long)outputParams[4].Value,
                IsNewlyCreated = (bool)outputParams[5].Value
            },
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

        SqlParameter[] parameters = new[]
        {
            new SqlParameter("@PhoneNumber", phoneNumber),
            new SqlParameter("@Region", region),
            new SqlParameter("@AppDeviceId", appDeviceId),
            new SqlParameter("@Purpose", purpose),
            new SqlParameter("@ConnectionId", connectionId ?? (object)DBNull.Value),
            new SqlParameter("@FlowUniqueId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output },
            new SqlParameter("@Outcome", SqlDbType.NVarChar, 50) { Direction = ParameterDirection.Output },
            new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output }
        };

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
                    return new VerificationFlowData
                    {
                        FlowUniqueId = flowId,
                        ExpiresAt = DateTime.UtcNow.AddMinutes(15)
                    };
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

        SqlParameter[] parameters = new[]
        {
            new SqlParameter("@FlowUniqueId", flowUniqueId),
            new SqlParameter("@OtpLength", otpLength),
            new SqlParameter("@ExpiryMinutes", expiryMinutes),
            new SqlParameter("@OtpCode", SqlDbType.NVarChar, 10) { Direction = ParameterDirection.Output },
            new SqlParameter("@OtpUniqueId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output },
            new SqlParameter("@Outcome", SqlDbType.NVarChar, 50) { Direction = ParameterDirection.Output },
            new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output }
        };

        StoredProcedureResult<OtpGenerationData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.SP_GenerateOtpCode",
            parameters,
            outputParams =>
            {
                string outcome = outputParams[5].Value?.ToString() ?? "error";
                string? errorMessage = outputParams[6].Value?.ToString();

                if (outcome == "success")
                {
                    return new OtpGenerationData
                    {
                        OtpCode = outputParams[3].Value?.ToString() ?? "",
                        OtpUniqueId = (Guid)outputParams[4].Value,
                        ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes)
                    };
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
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Verifying OTP code for flow: {FlowId}", flowUniqueId);

        SqlParameter[] parameters = new[]
        {
            new SqlParameter("@FlowUniqueId", flowUniqueId),
            new SqlParameter("@OtpCode", otpCode),
            new SqlParameter("@IpAddress", ipAddress ?? (object)DBNull.Value),
            new SqlParameter("@UserAgent", userAgent ?? (object)DBNull.Value),
            new SqlParameter("@IsValid", SqlDbType.Bit) { Direction = ParameterDirection.Output },
            new SqlParameter("@Outcome", SqlDbType.NVarChar, 50) { Direction = ParameterDirection.Output },
            new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output },
            new SqlParameter("@VerifiedAt", SqlDbType.DateTime2) { Direction = ParameterDirection.Output }
        };

        StoredProcedureResult<OtpVerificationData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.SP_VerifyOtpCode",
            parameters,
            outputParams =>
            {
                bool isValid = (bool)outputParams[4].Value;
                string outcome = outputParams[5].Value?.ToString() ?? "invalid";
                string? errorMessage = outputParams[6].Value?.ToString();
                DateTime? verifiedAt = outputParams[7].Value != DBNull.Value ? (DateTime?)outputParams[7].Value : null;

                return new OtpVerificationData
                {
                    IsValid = isValid,
                    VerifiedAt = verifiedAt,
                    RemainingAttempts = outcome.Contains("attempts remaining") ?
                        int.Parse(outcome.Split(" ")[0]) : 0
                };
            },
            cancellationToken);

        return result;
    }
}