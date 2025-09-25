using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using System.Data;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;
using Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;

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
            outputParams => new PhoneNumberData{
                PhoneNumberId = (long)outputParams[2].Value,
                UniqueId = (Guid)outputParams[3].Value,
                IsNewlyCreated = (bool)outputParams[4].Value
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

        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_InitiateVerificationFlow",
            parameters,
            outputParams => new VerificationFlowData{
                FlowUniqueId = (Guid)outputParams[5].Value,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15)
            },
            outcomeIndex: 6,
            errorIndex: 7,
            cancellationToken
        );
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

        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_GenerateOtpCode",
            parameters,
            outputParams => new OtpGenerationData{
                OtpCode = outputParams[3].Value?.ToString() ?? "",
                OtpUniqueId = (Guid)outputParams[4].Value,
                ExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes)
            },
            outcomeIndex: 5,
            errorIndex: 6,
            cancellationToken
        );
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

        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_VerifyOtpCode",
            parameters,
            outputParams =>
            {
                string outcome = outputParams[3].Value?.ToString() ?? "invalid";
                return new OtpVerificationData{
                    IsValid = (bool)outputParams[2].Value,
                    VerifiedAt = outputParams[5].Value != DBNull.Value ? (DateTime?)outputParams[7].Value : null,
                    RemainingAttempts = outcome.Contains("attempts remaining") ? int.Parse(outcome.Split(" ")[0]) : 0
                };
            },
            outcomeIndex: 3,
            errorIndex: 4,
            cancellationToken
        );
    }

    public async Task<StoredProcedureResult<RequestResendOtpData>> RequestResendOtpCodeAsync(
        Guid flowUniqueId,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Requesting resend of OTP code for flow: {FlowId}", flowUniqueId);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@FlowUniqueId", flowUniqueId),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, Constants.OutcomeLength),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, Constants.ErrorMessageLength)
        ];
        
        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_RequestResendOtpCode",
            parameters,
            outputParams => new RequestResendOtpData{
                Outcome = outputParams[1].Value?.ToString() ?? "unknown"
            },
            outcomeIndex: 1,
            errorIndex: 2,
            cancellationToken
        );
    }

    public async Task<StoredProcedureResult<UpdateVerificationFlowStatusData>> UpdateVerificationFlowStatusAsync(
        Guid flowUniqueId,
        VerificationFlowStatus status,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Updating verification flow status for flow: {FlowId} to {Status}", flowUniqueId, status);

        SqlParameter[] parameters = 
        [
            SqlParameterHelper.In("@FlowUniqueId", flowUniqueId),
            SqlParameterHelper.In("@Status", status.ToString()),
            SqlParameterHelper.Return("@rowsAffected", SqlDbType.Int),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, Constants.OutcomeLength),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, Constants.ErrorMessageLength)
        ];
        
        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_UpdateVerificationFlowStatus",
            parameters,
            outputParams => new UpdateVerificationFlowStatusData{
                RowsAffected = (int)outputParams[2].Value
            },
            outcomeIndex: 3,
            errorIndex: 4,
            cancellationToken
        );
    }
}