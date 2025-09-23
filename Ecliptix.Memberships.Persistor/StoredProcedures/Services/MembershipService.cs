using System.Data;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;
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

    public async Task<StoredProcedureResult<CreateMembershipData>> CreateMembershipAsync(
        Guid verificationFlowIdentifier,
        long connectId,
        Guid otpIdentifier,
        MembershipCreationStatus createStatus,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Creating membership for ConnectId: {ConnectId}", connectId);

        SqlParameter[] parameters = new[]
        {
            new SqlParameter("@FlowUniqueId", verificationFlowIdentifier),
            new SqlParameter("@ConnectionId", connectId),
            new SqlParameter("@OtpUniqueId", otpIdentifier),
            new SqlParameter("@CreationStatus", createStatus.ToString()),
            new SqlParameter("@MembershipUniqueId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output },
            new SqlParameter("@Status", SqlDbType.NVarChar, 20) { Direction = ParameterDirection.Output },
            new SqlParameter("@ResultCreationStatus", SqlDbType.NVarChar, 20) { Direction = ParameterDirection.Output },
            new SqlParameter("@Outcome", SqlDbType.NVarChar, 100) { Direction = ParameterDirection.Output },
            new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output }
        };

        StoredProcedureResult<CreateMembershipData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.CreateMembership",
            parameters,
            outputParams =>
            {
                string outcome = outputParams[7].Value?.ToString() ?? "error";
                string? errorMessage = outputParams[8].Value?.ToString();

                if (Guid.TryParse(outputParams[4].Value?.ToString(), out Guid membershipUniqueId) &&
                    !string.IsNullOrEmpty(outputParams[5].Value?.ToString()) &&
                    !string.IsNullOrEmpty(outputParams[6].Value?.ToString()) &&
                    (outcome == "created" || outcome == "membership_already_exists"))
                {
                    return new CreateMembershipData(
                        MembershipUniqueId: membershipUniqueId,
                        Status: outputParams[5].Value?.ToString() ?? "",
                        CreationStatus: outputParams[6].Value?.ToString() ?? ""
                    );
                }

                // Handle rate limit as integer outcome
                if (int.TryParse(outcome, out int waitMinutes))
                {
                    throw new InvalidOperationException($"rate_limit_exceeded:{waitMinutes}");
                }

                throw new InvalidOperationException($"{outcome}:{errorMessage}");
            },
            cancellationToken);

        // Handle special error mapping for rate limit and known errors
        if (!result.IsSuccess && result.ErrorMessage != null)
        {
            if (result.ErrorMessage.StartsWith("rate_limit_exceeded:"))
            {
                string[] parts = result.ErrorMessage.Split(':');
                return StoredProcedureResult<CreateMembershipData>.Failure("rate_limit_exceeded", parts.Length > 1 ? parts[1] : null);
            }
            else if (result.ErrorMessage.Contains(":"))
            {
                string[] parts = result.ErrorMessage.Split(':', 2);
                return StoredProcedureResult<CreateMembershipData>.Failure(parts[0], parts[1]);
            }
        }

        return result;
    }

    public async Task<StoredProcedureResult<LoginMembershipData>> SignInMembershipAsync(
        string mobileNumber,
        CancellationToken cancellationToken = default)
    {
        SqlParameter[] parameters =
        [
            new("@MobileNumber", mobileNumber),
            new("@MembershipUniqueId", SqlDbType.UniqueIdentifier) { Direction = ParameterDirection.Output },
            new("@Status", SqlDbType.NVarChar, 20) { Direction = ParameterDirection.Output },
            new("@Outcome", SqlDbType.NVarChar, 100) { Direction = ParameterDirection.Output },
            new("@SecureKey", SqlDbType.VarBinary, -1) { Direction = ParameterDirection.Output }
        ];

        StoredProcedureResult<LoginMembershipData> result = await _executor.ExecuteWithOutputAsync(
            "dbo.SP_LoginMembership",
            parameters,
            outputParams => 
            {
                string outcome = outputParams[3].Value?.ToString() ?? "error";
                string? errorMessage = outputParams[4].Value?.ToString();
                
                if (outcome == "success")
                {
                    return new LoginMembershipData(
                        MembershipUniqueId: outputParams[1].Value as Guid? ?? Guid.Empty,
                        Status: outputParams[2].Value?.ToString() ?? "",
                        SecureKey: outputParams[4].Value as byte[] ?? []
                    );
                }
                
                throw new InvalidOperationException($"Failed to sign in: {outcome} - {errorMessage}");
            },
            cancellationToken);

        if (!result.IsSuccess)
        {
            return StoredProcedureResult<LoginMembershipData>.Failure(result.Outcome, result.ErrorMessage);
        }

        return result;
    }
}