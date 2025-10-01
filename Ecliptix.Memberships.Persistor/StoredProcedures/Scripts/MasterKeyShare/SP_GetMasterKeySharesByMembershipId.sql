-- ============================================================================
-- SP_GetMasterKeyShare - Get master key shares by membership
-- ============================================================================
-- Purpose: Returns all master key shares for a given membership, matching MasterKeyShareQueryRecord
-- Author: MrReptile
-- Created: 2025-10-01
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_GetMasterKeyShare
    @MembershipUniqueId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MembershipUniqueId,
        ShareIndex,
        EncryptedShare,
        ShareMetadata,
        StorageLocation,
        UniqueId
    FROM dbo.MasterKeyShares
    WHERE MembershipUniqueId = @MembershipUniqueId
      AND IsDeleted = 0
    ORDER BY ShareIndex ASC;
END
GO

