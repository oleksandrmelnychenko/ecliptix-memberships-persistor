-- ============================================================================
-- SP_UpdateMembershipSecureKey - Update membership secure key with logging
-- ============================================================================
-- Purpose: Updates the secure key for an existing membership and logs all events
-- Author: MrReptile
-- Created: 2025-09-24
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_UpdateMembershipSecureKey
    @MembershipUniqueId UNIQUEIDENTIFIER,
    @SecureKey VARBINARY(MAX),
    @MaskingKey VARBINARY(32),
    @Outcome NVARCHAR(100) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT,
    @Status NVARCHAR(20) OUTPUT,
    @CreationStatus NVARCHAR(20) OUTPUT
    AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNumberId UNIQUEIDENTIFIER;

    SET @Outcome = NULL;
    SET @ErrorMessage = NULL;
    SET @Status = NULL;
    SET @CreationStatus = NULL;

BEGIN TRY
BEGIN TRANSACTION;

        IF @SecureKey IS NULL OR DATALENGTH(@SecureKey) = 0
BEGIN
            SET @Outcome = 'invalid_secure_key';
            SET @ErrorMessage = 'Secure key cannot be empty';
ROLLBACK TRANSACTION;
RETURN;
END

        IF @MaskingKey IS NULL OR DATALENGTH(@MaskingKey) != 32
BEGIN
            SET @Outcome = 'invalid_masking_key';
            SET @ErrorMessage = 'Masking key must be exactly 32 bytes';
ROLLBACK TRANSACTION;
RETURN;
END

SELECT @MobileNumberId = MobileNumberId
FROM dbo.Memberships
WHERE UniqueId = @MembershipUniqueId AND IsDeleted = 0;

IF @@ROWCOUNT = 0
BEGIN
            SET @Outcome = 'membership_not_found';
            SET @ErrorMessage = 'Membership not found or deleted';
ROLLBACK TRANSACTION;
RETURN;
END

UPDATE dbo.Memberships
SET SecureKey = @SecureKey,
    MaskingKey = @MaskingKey,
    Status = 'active',
    CreationStatus = 'secure_key_set'
WHERE UniqueId = @MembershipUniqueId;

IF @@ROWCOUNT = 0
BEGIN
EXEC dbo.LogMembershipAttempt @MobileNumberId, 'update_failed', 0;
            SET @Outcome = 'update_failed';
            SET @ErrorMessage = 'Failed to update membership';
ROLLBACK TRANSACTION;
RETURN;
END

SELECT @Status = Status, @CreationStatus = CreationStatus
FROM dbo.Memberships
WHERE UniqueId = @MembershipUniqueId;

EXEC dbo.LogMembershipAttempt @MobileNumberId, 'secure_key_updated', 1;

        SET @Outcome = 'success';
        SET @ErrorMessage = NULL;

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        IF @MembershipUniqueId IS NOT NULL
            EXEC dbo.LogMembershipAttempt @MobileNumberId, 'update_failed', 0;
END CATCH
END;
GO
