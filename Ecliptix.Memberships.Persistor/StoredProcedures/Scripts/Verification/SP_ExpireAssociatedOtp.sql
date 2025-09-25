-- ============================================================================
-- SP_ExpireAssociatedOtp - Expire all pending OTP records for a verification flow
-- ============================================================================
-- Purpose: Marks all pending OTP records as expired for the specified verification flow
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_ExpireAssociatedOtp
    @FlowUniqueId UNIQUEIDENTIFIER,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Expire all pending OTP records for this flow
        UPDATE dbo.OtpRecords
        SET Status = 'expired',
            IsActive = 0,
            UpdatedAt = GETUTCDATE()
        WHERE FlowUniqueId = @FlowUniqueId
          AND Status = 'pending'
          AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Outcome = 'no_pending_otp';
            SET @ErrorMessage = 'No pending OTP records found for this flow';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SET @Outcome = 'expired';

        -- Log the expiration event
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_expired',
            @Message = 'All pending OTP records expired for flow',
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
            @EventType = 'otp_expire_error',
            @Severity = 'error',
            @Message = 'Error expiring OTP records',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

