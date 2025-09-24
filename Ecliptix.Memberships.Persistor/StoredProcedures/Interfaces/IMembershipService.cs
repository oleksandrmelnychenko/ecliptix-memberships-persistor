using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;

public interface IMembershipService
{
    Task<StoredProcedureResult<MembershipQueryData>> CreateMembershipAsync(
        Guid verificationFlowIdentifier,
        long connectId,
        Guid otpIdentifier,
        MembershipCreationStatus createStatus,
        CancellationToken cancellationToken = default);
    
    Task<StoredProcedureResult<MembershipQueryData>> SignInMembershipAsync(
        string mobileNumber,
        CancellationToken cancellationToken = default);
    
    Task<StoredProcedureResult<MembershipQueryData>> UpdateMembershipSecureKeyAsync(
        Guid membershipIdentifier,
        byte[] secureKey,
        CancellationToken cancellationToken = default);
}