-- ============================================================================
-- SP_RequestResendOtpCode - Request resend OTP code for verification flow
-- ============================================================================
-- Purpose: Handles business logic for resending OTP code in a verification flow
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_RequestResendOtpCode
    @FlowUniqueId UNIQUEIDENTIFIER,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaxOtpAttempts INT = 5;
    DECLARE @MinResendIntervalSeconds INT = 30;
    DECLARE @OtpCount SMALLINT;
    DECLARE @SessionExpiresAt DATETIME2(7);
    DECLARE @LastOtpTimestamp DATETIME2(7);
    DECLARE @CurrentTime DATETIME2(7) = GETUTCDATE();

    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Get verification flow data
        SELECT
            @OtpCount = OtpCount,
            @SessionExpiresAt = ExpiresAt
        FROM dbo.VerificationFlows
        WHERE UniqueId = @FlowUniqueId
          AND IsDeleted = 0
          AND Status = 'pending';

        -- If flow not found or inactive, exit early
        IF @SessionExpiresAt IS NULL
        BEGIN
            SET @Outcome = 'flow_not_found_or_invalid';
            SET @ErrorMessage = 'Verification flow not found or inactive';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Get last OTP creation time for this flow
        SELECT @LastOtpTimestamp = MAX(CreatedAt)
        FROM dbo.OtpRecords
        WHERE FlowUniqueId = @FlowUniqueId;

        -- 3. Business checks
        IF @CurrentTime >= @SessionExpiresAt
        BEGIN
            UPDATE dbo.VerificationFlows
            SET Status = 'expired'
            WHERE UniqueId = @FlowUniqueId;

            SET @Outcome = 'flow_expired';
            SET @ErrorMessage = 'Verification flow expired';
        END
        ELSE IF @OtpCount >= @MaxOtpAttempts
        BEGIN
            UPDATE dbo.VerificationFlows
            SET Status = 'failed'
            WHERE UniqueId = @FlowUniqueId;

            SET @Outcome = 'max_otp_attempts_reached';
            SET @ErrorMessage = 'Maximum OTP attempts reached';
        END
        ELSE IF @LastOtpTimestamp IS NOT NULL
             AND DATEDIFF(second, @LastOtpTimestamp, @CurrentTime) < @MinResendIntervalSeconds
        BEGIN
            SET @Outcome = 'resend_cooldown_active';
            SET @ErrorMessage = CONCAT('Resend cooldown active. Please wait ', 
                @MinResendIntervalSeconds - DATEDIFF(second, @LastOtpTimestamp, @CurrentTime), ' seconds.');
        END
        ELSE
        BEGIN
            SET @Outcome = 'resend_allowed';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_resend_error',
            @Severity = 'error',
            @Message = 'Error during OTP resend request',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

