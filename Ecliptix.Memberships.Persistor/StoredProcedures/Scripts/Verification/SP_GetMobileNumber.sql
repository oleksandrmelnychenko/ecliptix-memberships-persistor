-- ============================================================================
-- SP_GetMobileNumber - Get mobile number and region by identifier
-- ============================================================================
-- Purpose: Returns mobile number, region, and unique id for a given identifier
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_GetMobileNumber
    @MobileUniqueId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNumber NVARCHAR(18);
    DECLARE @Region NVARCHAR(2);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Get Mobile number record
        SELECT TOP 1
            @MobileNumber = Number,
            @Region = Region
        FROM dbo.MobileNumbers
        WHERE UniqueId = @MobileUniqueId
          AND IsDeleted = 0;

        IF @MobileNumber IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT
                CAST(NULL AS NVARCHAR(18)) AS MobileNumber,
                CAST(NULL AS NVARCHAR(2)) AS Region,
                @MobileUniqueId AS UniqueId;
            RETURN;
        END

        COMMIT TRANSACTION;

        -- Return found result
        SELECT
            @MobileNumber AS MobileNumber,
            @Region AS Region,
            @MobileUniqueId AS UniqueId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(500) = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'get_mobile_number_error',
            @Severity = 'error',
            @Message = 'Error during mobile number retrieval',
            @Details = @ErrorMessage

        -- Return error result
        SELECT
            CAST(NULL AS NVARCHAR(18)) AS MobileNumber,
            CAST(NULL AS NVARCHAR(2)) AS Region,
            CAST(CAST(0 AS BINARY(16)) AS UNIQUEIDENTIFIER) AS UniqueId;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

