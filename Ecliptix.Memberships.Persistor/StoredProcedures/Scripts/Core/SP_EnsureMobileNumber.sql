-- ============================================================================
-- SP_EnsureMobileNumber - Get or create mobile number record
-- ============================================================================
-- Purpose: Ensures a mobile number exists in the database, creates if needed
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_EnsureMobileNumber
    @MobileNumber NVARCHAR(18),
    @Region NVARCHAR(2) = NULL,
    @AppDeviceId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNumberId BIGINT;
    DECLARE @UniqueId UNIQUEIDENTIFIER;
    DECLARE @Success BIT = 0;
    DECLARE @Outcome NVARCHAR(100) = 'error';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate input
        IF @MobileNumber IS NULL OR LEN(@MobileNumber) = 0
        BEGIN
            SET @Outcome = 'invalid_mobile_number';
            ROLLBACK TRANSACTION;
            SELECT @UniqueId AS UniqueId, @Outcome AS Outcome, @Success AS Success;
            RETURN;
        END

        -- Check if mobile number already exists
        SELECT @MobileNumberId = Id, @UniqueId = UniqueId
        FROM dbo.MobileNumbers
        WHERE Number = @MobileNumber
          AND (Region = @Region OR (Region IS NULL AND @Region IS NULL))
          AND IsDeleted = 0;

        -- Create if doesn't exist
        IF @MobileNumberId IS NULL
        BEGIN
            SET @UniqueId = NEWID();

            INSERT INTO dbo.MobileNumbers (Number, Region, UniqueId, CreatedAt, UpdatedAt, IsDeleted)
            VALUES (@MobileNumber, @Region, @UniqueId, GETUTCDATE(), GETUTCDATE(), 0);

            SET @MobileNumberId = SCOPE_IDENTITY();
            SET @Outcome = 'created';
            SET @Success = 1;

            -- Log creation
            EXEC dbo.SP_LogEvent
                @EventType = 'Mobile_number_created',
                @Message = 'New Mobile number registered',
                @EntityType = 'MobileNumber',
                @EntityId = @MobileNumberId
        END
        ELSE
        BEGIN
            SET @Outcome = 'already_exists';
            SET @Success = 1;
        END

        COMMIT TRANSACTION;

        -- Return result set
        SELECT @UniqueId AS UniqueId, @Outcome AS Outcome, @Success AS Success;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Return error result
        SELECT CAST(CAST(0 AS BINARY(16)) AS UNIQUEIDENTIFIER) AS UniqueId,
               @ErrorMessage AS Outcome,
               CAST(0 AS BIT) AS Success;

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO