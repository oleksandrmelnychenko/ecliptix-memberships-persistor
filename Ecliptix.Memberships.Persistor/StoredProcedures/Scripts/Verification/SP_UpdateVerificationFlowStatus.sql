-- ============================================================================
-- SP_UpdateVerificationFlowStatus - Update status for verification flow
-- ============================================================================
-- Purpose: Updates the status of a verification flow and sets expiry if verified
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_UpdateVerificationFlowStatus
    @FlowUniqueId UNIQUEIDENTIFIER,
    @NewStatus NVARCHAR(20),
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT,
    @RowsAffected INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;
    SET @RowsAffected = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Update verification flow status
        UPDATE dbo.VerificationFlows
        SET Status = @NewStatus,
            ExpiresAt = CASE WHEN @NewStatus = 'verified' THEN DATEADD(hour, 24, GETUTCDATE()) ELSE ExpiresAt END,
            UpdatedAt = GETUTCDATE()
        WHERE UniqueId = @FlowUniqueId
          AND IsDeleted = 0;

        SET @RowsAffected = @@ROWCOUNT;

        IF @RowsAffected = 0
        BEGIN
            SET @Outcome = 'not_found';
            SET @ErrorMessage = 'Verification flow not found or already deleted';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SET @Outcome = 'updated';

        -- Log status update
        EXEC dbo.SP_LogEvent
            @EventType = 'verification_flow_status_updated',
            @Message = CONCAT('Verification flow status updated to ', @NewStatus),
            @EntityType = 'VerificationFlow',
            @EntityId = @FlowUniqueId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'verification_flow_status_error',
            @Severity = 'error',
            @Message = 'Error during verification flow status update',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

