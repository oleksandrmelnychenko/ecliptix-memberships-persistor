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
}