-- ============================================================================
-- SP_CreateMasterKeyShare - Create new master key share for membership
-- ============================================================================
-- Purpose: Creates a new master key share for a membership, with validation and logging
-- Author: MrReptile
-- Created: 2025-10-01
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_CreateMasterKeySharesByMembershipId
    @MembershipUniqueId UNIQUEIDENTIFIER,
    @ShareIndex INT,
    @EncryptedShare VARBINARY(MAX),
    @ShareMetadata NVARCHAR(MAX),
    @StorageLocation NVARCHAR(100),
    @MasterKeyShareUniqueId UNIQUEIDENTIFIER OUTPUT,
    @IsSuccess BIT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @MasterKeyShareUniqueId = NULL;
    SET @IsSuccess = 0;
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate membership exists
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Memberships WHERE UniqueId = @MembershipUniqueId AND IsDeleted = 0
        )
        BEGIN
            SET @ErrorMessage = 'Membership not found';
            SET @IsSuccess = 0;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Check for duplicate share index for this membership
        IF EXISTS (
            SELECT 1 FROM dbo.MasterKeyShares WHERE MembershipUniqueId = @MembershipUniqueId AND ShareIndex = @ShareIndex
        )
        BEGIN
            SET @ErrorMessage = 'Master key share with this index already exists for membership';
            SET @IsSuccess = 0;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Insert new master key share
        DECLARE @OutputTable TABLE (UniqueId UNIQUEIDENTIFIER);
        INSERT INTO dbo.MasterKeyShares (
            MembershipUniqueId, ShareIndex, EncryptedShare, ShareMetadata, StorageLocation, CreatedAt, UpdatedAt, IsDeleted
        )
        OUTPUT inserted.UniqueId INTO @OutputTable
        VALUES (
            @MembershipUniqueId, @ShareIndex, @EncryptedShare, @ShareMetadata, @StorageLocation, GETUTCDATE(), GETUTCDATE(), 0
        );

        SELECT @MasterKeyShareUniqueId = UniqueId FROM @OutputTable;
        SET @IsSuccess = 1;


        -- Log event
        EXEC dbo.SP_LogEvent
            @EventType = 'master_key_share_created',
            @Severity = 'info',
            @Message = 'Master key share created',
            @EntityType = 'MasterKeyShare',
            @EntityId = @MasterKeyShareUniqueId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @IsSuccess = 0;
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log error
        EXEC dbo.SP_LogEvent
            @EventType = 'master_key_share_creation_failed',
            @Severity = 'error',
            @Message = @ErrorMessage,
            @EntityType = 'MasterKeyShare',
            @EntityId = @MasterKeyShareUniqueId;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO
