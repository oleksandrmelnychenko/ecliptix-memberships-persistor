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
    @MobileNumberId BIGINT OUTPUT,
    @UniqueId UNIQUEIDENTIFIER OUTPUT,
    @IsNewlyCreated BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsNewlyCreated = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

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

            INSERT INTO dbo.MobileNumbers (Number, Region, UniqueId, CreatedAt, UpdatedAt)
            VALUES (@MobileNumber, @Region, @UniqueId, GETUTCDATE(), GETUTCDATE());

            SET @MobileNumberId = SCOPE_IDENTITY();
            SET @IsNewlyCreated = 1;

            -- Log creation
            EXEC dbo.SP_LogEvent
                @EventType = 'Mobile_number_created',
                @Message = 'New Mobile number registered',
                @EntityType = 'MobileNumber',
                @EntityId = @MobileNumberId;
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO