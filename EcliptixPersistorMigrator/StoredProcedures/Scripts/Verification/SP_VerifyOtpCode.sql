-- ============================================================================
-- SP_VerifyOtpCode - Verify OTP code for verification flow
-- ============================================================================
-- Purpose: Verifies submitted OTP code and completes verification flow
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_VerifyOtpCode
    @FlowUniqueId UNIQUEIDENTIFIER,
    @OtpCode NVARCHAR(10),
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL,
    @IsValid BIT OUTPUT,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT,
    @VerifiedAt DATETIME2(7) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FlowId BIGINT;
    DECLARE @OtpId BIGINT;
    DECLARE @MaxAttempts INT = 3;
    DECLARE @CurrentAttempts INT;

    SET @IsValid = 0;
    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;
    SET @VerifiedAt = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Get verification flow
        SELECT @FlowId = Id
        FROM dbo.VerificationFlows
        WHERE UniqueId = @FlowUniqueId
          AND Status = 'pending'
          AND ExpiresAt > GETUTCDATE()
          AND IsDeleted = 0;

        IF @FlowId IS NULL
        BEGIN
            SET @Outcome = 'flow_expired';
            SET @ErrorMessage = 'Verification flow not found or expired';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Find active OTP code
        SELECT @OtpId = Id, @CurrentAttempts = AttemptCount
        FROM dbo.OtpCodes
        WHERE VerificationFlowId = @FlowId
          AND OtpValue = @OtpCode
          AND Status = 'active'
          AND ExpiresAt > GETUTCDATE()
          AND IsDeleted = 0;

        IF @OtpId IS NOT NULL
        BEGIN
            -- 3. Valid OTP code found
            SET @IsValid = 1;
            SET @Outcome = 'verified';
            SET @VerifiedAt = GETUTCDATE();

            -- Update OTP status
            UPDATE dbo.OtpCodes
            SET Status = 'used',
                VerifiedAt = @VerifiedAt,
                UpdatedAt = @VerifiedAt
            WHERE Id = @OtpId;

            -- Update flow status
            UPDATE dbo.VerificationFlows
            SET Status = 'verified',
                UpdatedAt = @VerifiedAt
            WHERE Id = @FlowId;

            -- Log successful verification
            EXEC dbo.SP_LogEvent
                @EventType = 'otp_verified',
                @Message = 'OTP code successfully verified',
                @EntityType = 'VerificationFlow',
                @EntityId = @FlowId,
                @IpAddress = @IpAddress,
                @UserAgent = @UserAgent;

        END
        ELSE
        BEGIN
            -- 4. Invalid OTP - check if any OTP exists for this flow
            SELECT TOP 1 @OtpId = Id, @CurrentAttempts = AttemptCount
            FROM dbo.OtpCodes
            WHERE VerificationFlowId = @FlowId
              AND Status = 'active'
              AND IsDeleted = 0
            ORDER BY CreatedAt DESC;

            IF @OtpId IS NOT NULL
            BEGIN
                -- 5. Record failed attempt
                SET @CurrentAttempts = @CurrentAttempts + 1;

                UPDATE dbo.OtpCodes
                SET AttemptCount = @CurrentAttempts,
                    UpdatedAt = GETUTCDATE()
                WHERE Id = @OtpId;

                -- Log failed attempt
                INSERT INTO dbo.FailedOtpAttempts (
                    OtpRecordId, AttemptedValue, FailureReason,
                    IpAddress, UserAgent, AttemptedAt, CreatedAt, UpdatedAt
                )
                VALUES (
                    @OtpId, @OtpCode, 'invalid_code',
                    @IpAddress, @UserAgent, GETUTCDATE(), GETUTCDATE(), GETUTCDATE()
                );

                -- 6. Check if max attempts exceeded
                IF @CurrentAttempts >= @MaxAttempts
                BEGIN
                    -- Mark OTP as invalid and flow as failed
                    UPDATE dbo.OtpCodes
                    SET Status = 'invalid'
                    WHERE Id = @OtpId;

                    UPDATE dbo.VerificationFlows
                    SET Status = 'failed'
                    WHERE Id = @FlowId;

                    SET @Outcome = 'max_attempts_exceeded';
                    SET @ErrorMessage = 'Maximum verification attempts exceeded';

                    -- Log max attempts exceeded
                    EXEC dbo.SP_LogEvent
                        @EventType = 'otp_max_attempts_exceeded',
                        @Severity = 'warning',
                        @Message = 'Maximum OTP verification attempts exceeded',
                        @EntityType = 'VerificationFlow',
                        @EntityId = @FlowId,
                        @IpAddress = @IpAddress,
                        @UserAgent = @UserAgent;
                END
                ELSE
                BEGIN
                    SET @Outcome = 'invalid_code';
                    SET @ErrorMessage = CONCAT('Invalid OTP code. ', (@MaxAttempts - @CurrentAttempts), ' attempts remaining.');
                END
            END
            ELSE
            BEGIN
                SET @Outcome = 'no_active_otp';
                SET @ErrorMessage = 'No active OTP code found for this verification flow';
            END

            -- Log failed verification if not max attempts
            IF @Outcome != 'max_attempts_exceeded'
            BEGIN
                EXEC dbo.SP_LogEvent
                    @EventType = 'otp_verification_failed',
                    @Message = 'OTP verification failed',
                    @Details = @ErrorMessage,
                    @EntityType = 'VerificationFlow',
                    @EntityId = @FlowId,
                    @IpAddress = @IpAddress,
                    @UserAgent = @UserAgent;
            END
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
            @EventType = 'otp_verification_error',
            @Severity = 'error',
            @Message = 'Error during OTP verification',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO