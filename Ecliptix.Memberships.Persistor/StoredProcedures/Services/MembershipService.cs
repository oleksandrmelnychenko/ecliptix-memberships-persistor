using System.Data;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;
using Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Services;

public class MembershipService : IMembershipService
{
    private readonly IStoredProcedureExecutor _executor;
    private readonly ILogger<MembershipService> _logger;
    
    public MembershipService(IStoredProcedureExecutor executor, ILogger<MembershipService> logger)
    {
        _executor = executor;
        _logger = logger;
    }

    public async Task<StoredProcedureResult<MembershipQueryData>> CreateMembershipAsync(
        Guid verificationFlowIdentifier,
        long connectId,
        Guid otpIdentifier,
        MembershipCreationStatus createStatus,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Creating membership for ConnectId: {ConnectId}", connectId);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@FlowUniqueId", verificationFlowIdentifier),
            SqlParameterHelper.In("@ConnectionId", connectId),
            SqlParameterHelper.In("@OtpUniqueId", otpIdentifier),
            SqlParameterHelper.In("@CreationStatus", createStatus.ToString()),
            SqlParameterHelper.Out("@MembershipUniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@Status", SqlDbType.NVarChar, 20),
            SqlParameterHelper.Out("@ResultCreationStatus", SqlDbType.NVarChar, 20),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, 100),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, 500)
        ];

        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_CreateMembership",
            parameters,
            outputParams =>
            {
                string? status = outputParams[5].Value?.ToString();
                string? creationStatus = outputParams[6].Value?.ToString();
                return new MembershipQueryData
                {
                    UniqueIdentifier = (Guid)outputParams[4].Value,
                    ActivityStatus = ProcedureResultMapper.ToActivityStatus(status, _logger),
                    CreationStatus = ProcedureResultMapper.ToCreationStatus(creationStatus, _logger),
                };
            },
            outcomeIndex: 7,
            errorIndex: 8,
            cancellationToken
        );
    }

    public async Task<StoredProcedureResult<MembershipQueryData>> SignInMembershipAsync(
        string mobileNumber,
        CancellationToken cancellationToken = default)
    {
        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@MobileNumber", mobileNumber),
            SqlParameterHelper.Out("@MembershipUniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@Status", SqlDbType.NVarChar, 20),
            SqlParameterHelper.Out("@SecureKey", SqlDbType.VarBinary, -1),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, 100),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, 500)
        ];

        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_LoginMembership",
            parameters,
            outputParams =>
            {
                string? activity = outputParams[2].Value?.ToString();
                return new MembershipQueryData
                {
                    UniqueIdentifier = (Guid)outputParams[1].Value,
                    ActivityStatus = ProcedureResultMapper.ToActivityStatus(activity, _logger),
                    SecureKey = outputParams[3].Value as byte[] ?? []
                };
            },
            outcomeIndex: 4,
            errorIndex: 5,
            cancellationToken
        );
    }

    public async Task<StoredProcedureResult<MembershipQueryData>> UpdateMembershipSecureKeyAsync(
        Guid membershipUniqueId,
        byte[] secretKey,
        CancellationToken cancellationToken = default)
    {
        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@MembershipUniqueId", membershipUniqueId),
            SqlParameterHelper.In("@SecureKey", secretKey),
            SqlParameterHelper.Out("@MembershipUniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@Status", SqlDbType.NVarChar, 50),
            SqlParameterHelper.Out("@CreationStatus", SqlDbType.NVarChar, 50),
            SqlParameterHelper.Out("@Outcome", SqlDbType.NVarChar, 100),
            SqlParameterHelper.Out("@ErrorMessage", SqlDbType.NVarChar, 500)
        ];

        return await _executor.ExecuteWithOutcomeAsync(
            "dbo.SP_UpdateMembershipSecureKey",
            parameters,
            outputParams =>
            {
                string? status = outputParams[3].Value?.ToString();
                string? creationStatus = outputParams[4].Value?.ToString();
                
                return new MembershipQueryData
                {
                    UniqueIdentifier = (Guid)outputParams[2].Value,
                    ActivityStatus = ProcedureResultMapper.ToActivityStatus(status, _logger),
                    CreationStatus = ProcedureResultMapper.ToCreationStatus(creationStatus, _logger),
                };
            },
            outcomeIndex: 5,
            errorIndex: 6,
            cancellationToken
        );
    }
}