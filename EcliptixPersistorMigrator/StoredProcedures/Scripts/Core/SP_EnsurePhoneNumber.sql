-- ============================================================================
-- SP_EnsurePhoneNumber - Get or create phone number record
-- ============================================================================
-- Purpose: Ensures a phone number exists in the database, creates if needed
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_EnsurePhoneNumber
    @PhoneNumber NVARCHAR(18),
    @Region NVARCHAR(2) = NULL,
    @PhoneNumberId BIGINT OUTPUT,
    @UniqueId UNIQUEIDENTIFIER OUTPUT,
    @IsNewlyCreated BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsNewlyCreated = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check if phone number already exists
        SELECT @PhoneNumberId = Id, @UniqueId = UniqueId
        FROM dbo.MobileNumbers
        WHERE PhoneNumber = @PhoneNumber
          AND (Region = @Region OR (Region IS NULL AND @Region IS NULL))
          AND IsDeleted = 0;

        -- Create if doesn't exist
        IF @PhoneNumberId IS NULL
        BEGIN
            SET @UniqueId = NEWID();

            INSERT INTO dbo.MobileNumbers (PhoneNumber, Region, UniqueId, CreatedAt, UpdatedAt)
            VALUES (@PhoneNumber, @Region, @UniqueId, GETUTCDATE(), GETUTCDATE());

            SET @PhoneNumberId = SCOPE_IDENTITY();
            SET @IsNewlyCreated = 1;

            -- Log creation
            EXEC dbo.SP_LogEvent
                @EventType = 'phone_number_created',
                @Message = 'New phone number registered',
                @EntityType = 'MobileNumber',
                @EntityId = @PhoneNumberId;
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