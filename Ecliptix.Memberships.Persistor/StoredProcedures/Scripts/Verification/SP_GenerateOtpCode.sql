-- ============================================================================
-- SP_GenerateOtpCode - Generate OTP code for verification flow
-- ============================================================================
-- Purpose: Generates a new OTP code for an active verification flow
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_GenerateOtpCode
    @FlowUniqueId UNIQUEIDENTIFIER,
    @OtpLength INT = 6,
    @ExpiryMinutes INT = 5,
    @OtpCode NVARCHAR(10) OUTPUT,
    @OtpUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FlowId BIGINT;
    DECLARE @MaxOtpCount INT = 5;
    DECLARE @CurrentOtpCount INT;

    SET @Outcome = 'error';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate verification flow exists and is active
        SELECT @FlowId = Id, @CurrentOtpCount = OtpCount
        FROM dbo.VerificationFlows
        WHERE UniqueId = @FlowUniqueId
          AND Status = 'pending'
          AND ExpiresAt > GETUTCDATE()
          AND IsDeleted = 0;

        IF @FlowId IS NULL
        BEGIN
            SET @Outcome = 'flow_not_found';
            SET @ErrorMessage = 'Verification flow not found or expired';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Check OTP generation limit
        IF @CurrentOtpCount >= @MaxOtpCount
        BEGIN
            SET @Outcome = 'otp_limit_exceeded';
            SET @ErrorMessage = 'Maximum OTP generation attempts exceeded';

            -- Mark flow as failed
            UPDATE dbo.VerificationFlows
            SET Status = 'failed', UpdatedAt = GETUTCDATE()
            WHERE Id = @FlowId;

            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Expire any existing active OTP codes for this flow
        UPDATE dbo.OtpCodes
        SET Status = 'expired', UpdatedAt = GETUTCDATE()
        WHERE VerificationFlowId = @FlowId
          AND Status = 'active'
          AND IsDeleted = 0;

        -- 4. Generate random OTP code
        DECLARE @RandomSeed INT = ABS(CHECKSUM(NEWID()));
        DECLARE @i INT = 0;
        SET @OtpCode = '';

        WHILE @i < @OtpLength
        BEGIN
            DECLARE @Digit INT = (@RandomSeed + @i * 7) % 10;
            SET @OtpCode = @OtpCode + CAST(@Digit AS NVARCHAR(1));
            SET @i = @i + 1;
            SET @RandomSeed = @RandomSeed / 10 + (@RandomSeed % 10) * 1000;
        END

        -- 5. Ensure OTP is unique (very unlikely collision, but safety first)
        WHILE EXISTS (
            SELECT 1 FROM dbo.OtpCodes
            WHERE OtpValue = @OtpCode
              AND Status = 'active'
              AND ExpiresAt > GETUTCDATE()
        )
        BEGIN
            SET @RandomSeed = ABS(CHECKSUM(NEWID()));
            SET @OtpCode = RIGHT('000000' + CAST(@RandomSeed % 1000000 AS NVARCHAR(6)), @OtpLength);
        END

        -- 6. Create new OTP record
        SET @OtpUniqueId = NEWID();

        INSERT INTO dbo.OtpCodes (
            VerificationFlowId, OtpValue, Status, ExpiresAt,
            AttemptCount, UniqueId, CreatedAt, UpdatedAt
        )
        VALUES (
            @FlowId, @OtpCode, 'active', DATEADD(minute, @ExpiryMinutes, GETUTCDATE()),
            0, @OtpUniqueId, GETUTCDATE(), GETUTCDATE()
        );

        -- 7. Update flow OTP count
        UPDATE dbo.VerificationFlows
        SET OtpCount = @CurrentOtpCount + 1, UpdatedAt = GETUTCDATE()
        WHERE Id = @FlowId;

        -- 8. Log OTP generation
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_generated',
            @Severity = 'info',
            @Message = 'OTP code generated',
            @EntityType = 'OtpCode',
            @EntityId = @OtpUniqueId;
        -- ^ Use @OtpUniqueId instead of SCOPE_IDENTITY() to match the inserted OTP

        COMMIT TRANSACTION;

        SET @Outcome = 'success';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_generation_failed',
            @Severity = 'error',
            @Message = @ErrorMessage,
            @EntityType = 'OtpCode',
            @EntityId = @OtpUniqueId;
        -- ^ Use @OtpUniqueId for consistency (may be NULL if error before assignment)

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO