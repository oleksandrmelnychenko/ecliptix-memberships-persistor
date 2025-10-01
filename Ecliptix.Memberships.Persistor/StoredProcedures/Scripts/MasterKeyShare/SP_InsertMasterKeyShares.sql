-- ============================================================================
-- SP_InsertMasterKeyShares - Batch insert master key shares using TVP
-- ============================================================================
-- Purpose: Inserts multiple master key shares in a single transaction
-- Author: EcliptixPersistor
-- Created: 2025-10-01
-- ============================================================================

-- 1. Create Table-Valued Parameter Type if not exists
IF NOT EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'MasterKeyShareTableType')
BEGIN
    CREATE TYPE dbo.MasterKeyShareTableType AS TABLE
    (
        ShareIndex INT NOT NULL,
        EncryptedShare VARBINARY(MAX) NOT NULL,
        ShareMetadata NVARCHAR(MAX) NOT NULL,
        StorageLocation NVARCHAR(100) NOT NULL
    );
END
GO

-- 2. Create the stored procedure
CREATE OR ALTER PROCEDURE dbo.SP_InsertMasterKeyShares
    @MembershipUniqueId UNIQUEIDENTIFIER,
    @Shares dbo.MasterKeyShareTableType READONLY,
    @Success BIT OUTPUT,
    @Message NVARCHAR(500) OUTPUT,
    @SharesInserted INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MembershipId BIGINT;
    SET @Success = 0;
    SET @Message = NULL;
    SET @SharesInserted = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate membership exists and is active
        SELECT @MembershipId = Id
        FROM dbo.Memberships
        WHERE UniqueId = @MembershipUniqueId
          AND IsDeleted = 0;

        IF @MembershipId IS NULL
        BEGIN
            SET @Message = 'Membership not found or inactive';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Check if shares already exist for this membership
        IF EXISTS (
            SELECT 1
            FROM dbo.MasterKeyShares
            WHERE MembershipUniqueId = @MembershipUniqueId
              AND IsDeleted = 0
        )
        BEGIN
            SET @Message = 'Master key shares already exist for this membership';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Validate that shares table is not empty
        IF NOT EXISTS (SELECT 1 FROM @Shares)
        BEGIN
            SET @Message = 'No shares provided';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 4. Validate share indexes are sequential starting from 0
        DECLARE @ExpectedCount INT;
        DECLARE @ActualCount INT;

        SELECT @ActualCount = COUNT(*) FROM @Shares;
        SELECT @ExpectedCount = COUNT(DISTINCT ShareIndex) FROM @Shares;

        IF @ActualCount != @ExpectedCount
        BEGIN
            SET @Message = 'Duplicate share indexes detected';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check sequential indexes from 0
        IF EXISTS (
            SELECT 1
            FROM @Shares
            WHERE ShareIndex < 0 OR ShareIndex >= @ActualCount
        )
        BEGIN
            SET @Message = 'Share indexes must be sequential starting from 0';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 5. Insert all shares in batch
        INSERT INTO dbo.MasterKeyShares (
            MembershipUniqueId,
            ShareIndex,
            EncryptedShare,
            ShareMetadata,
            StorageLocation,
            UniqueId,
            CreatedAt,
            UpdatedAt,
            IsDeleted
        )
        SELECT
            @MembershipUniqueId,
            s.ShareIndex,
            s.EncryptedShare,
            s.ShareMetadata,
            s.StorageLocation,
            NEWID(),
            GETUTCDATE(),
            GETUTCDATE(),
            0
        FROM @Shares s;

        SET @SharesInserted = @@ROWCOUNT;

        -- 6. Log event
        DECLARE @SharesInsertedStr NVARCHAR(10) = CAST(@SharesInserted AS NVARCHAR(10));

        EXEC dbo.SP_LogEvent
            @EventType = 'master_key_shares_created',
            @Message = 'Master key shares batch inserted successfully',
            @EntityType = 'MasterKeyShare',
            @Details = @SharesInsertedStr

        SET @Success = 1;
        SET @Message = 'Shares inserted successfully';
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Log error
        EXEC dbo.SP_LogEvent
            @EventType = 'master_key_shares_insert_error',
            @Severity = 'error',
            @Message = @ErrorMessage,
            @EntityType = 'MasterKeyShare';

        SET @Success = 0;
        SET @Message = @ErrorMessage;

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
