-- ============================================================================
-- SP_GetMobileNumber - Get mobile number and region by identifier
-- ============================================================================
-- Purpose: Returns mobile number, region, and unique id for a given identifier
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_GetMobileNumber
    @MobileNumberIdentifier UNIQUEIDENTIFIER,
    @MobileNumber NVARCHAR(18) OUTPUT,
    @Region NVARCHAR(2) OUTPUT,
    @MobileNumberUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @MobileNumber = NULL;
    SET @Region = NULL;
    SET @MobileNumberUniqueId = NULL;
    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Get Mobile number record
        SELECT TOP 1
            @MobileNumber = Number,
            @Region = Region,
            @MobileNumberUniqueId = UniqueId
        FROM dbo.MobileNumbers
        WHERE UniqueId = @MobileNumberIdentifier
          AND IsDeleted = 0;

        IF @MobileNumber IS NULL
        BEGIN
            SET @Outcome = 'not_found';
            SET @ErrorMessage = 'Mobile number not found for the given identifier';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SET @Outcome = 'found';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'get_mobile_number_error',
            @Severity = 'error',
            @Message = 'Error during mobile number retrieval',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

