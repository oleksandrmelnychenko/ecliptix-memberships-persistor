-- ============================================================================
-- SP_UpdateOtpStatus - Update OTP status for verification flow
-- ============================================================================
-- Purpose: Updates the status of an OTP record and related verification flow
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_UpdateOtpStatus
    @OtpUniqueId UNIQUEIDENTIFIER,
    @NewStatus NVARCHAR(20),
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus NVARCHAR(20);
    DECLARE @FlowId BIGINT;
    DECLARE @FlowUniqueId UNIQUEIDENTIFIER;

    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Find OTP record and related flow
        SELECT 
            @CurrentStatus = o.Status,
            @FlowId = vf.Id,
            @FlowUniqueId = vf.UniqueId
        FROM dbo.OtpRecords AS o
        JOIN dbo.VerificationFlows AS vf ON o.FlowUniqueId = vf.UniqueId
        WHERE o.UniqueId = @OtpUniqueId
          AND o.IsDeleted = 0
          AND vf.IsDeleted = 0
          AND vf.Status = 'pending'
          AND vf.ExpiresAt > GETUTCDATE();

        IF @CurrentStatus IS NULL
        BEGIN
            SET @Outcome = 'not_found';
            SET @ErrorMessage = 'OTP not found, deleted, or flow invalid/expired';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @CurrentStatus = 'expired' AND @NewStatus = 'pending'
        BEGIN
            SET @Outcome = 'invalid_transition';
            SET @ErrorMessage = 'Cannot transition from expired to pending';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Update OTP status
        UPDATE dbo.OtpRecords
        SET Status = @NewStatus,
            IsActive = CASE WHEN @NewStatus = 'pending' THEN 1 ELSE 0 END,
            UpdatedAt = GETUTCDATE()
        WHERE UniqueId = @OtpUniqueId
          AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Outcome = 'update_failed';
            SET @ErrorMessage = 'Failed to update OTP: no rows affected';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Handle related actions
        IF @NewStatus = 'failed'
        BEGIN
            INSERT INTO dbo.FailedOtpAttempts (OtpUniqueId, FlowUniqueId, CreatedAt)
            VALUES (@OtpUniqueId, @FlowUniqueId, GETUTCDATE());
        END
        ELSE IF @NewStatus = 'verified'
        BEGIN
            UPDATE dbo.VerificationFlows
            SET Status = 'verified',
                UpdatedAt = GETUTCDATE()
            WHERE Id = @FlowId;
        END

        SET @Outcome = 'updated';

        -- Log status update
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_status_updated',
            @Message = CONCAT('OTP status updated to ', @NewStatus),
            @EntityType = 'OtpRecord',
            @EntityId = @OtpUniqueId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_status_update_error',
            @Severity = 'error',
            @Message = 'Error during OTP status update',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

