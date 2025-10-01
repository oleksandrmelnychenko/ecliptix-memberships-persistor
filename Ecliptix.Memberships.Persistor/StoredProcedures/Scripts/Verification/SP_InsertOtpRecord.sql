-- ============================================================================
-- SP_InsertOtpRecord - Insert pre-generated OTP record
-- ============================================================================
-- Purpose: Inserts an OTP record with pre-generated hash and salt from the server
-- Author: EcliptixPersistor
-- Created: 2025-10-01
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_InsertOtpRecord
    @FlowUniqueId UNIQUEIDENTIFIER,
    @OtpHash NVARCHAR(500),
    @OtpSalt NVARCHAR(500),
    @ExpiresAt DATETIME2,
    @Status NVARCHAR(20),
    @OtpUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Outcome NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FlowId BIGINT;
    DECLARE @OtpCount INT;
    DECLARE @MaxOtpAttempts INT = 5;

    SET @Outcome = 'error';
    SET @OtpUniqueId = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate that verification flow exists and is not expired
        SELECT @FlowId = Id, @OtpCount = OtpCount
        FROM dbo.VerificationFlows
        WHERE UniqueId = @FlowUniqueId
          AND IsDeleted = 0
          AND ExpiresAt > GETUTCDATE();

        IF @FlowId IS NULL
        BEGIN
            SET @Outcome = 'flow_not_found_or_invalid';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Check if max OTP attempts reached
        IF @OtpCount >= @MaxOtpAttempts
        BEGIN
            SET @Outcome = 'max_otp_attempts_reached';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Expire any existing active OTP codes for this flow
        UPDATE dbo.OtpCodes
        SET Status = 'expired',
            UpdatedAt = GETUTCDATE()
        WHERE VerificationFlowId = @FlowId
          AND Status = 'active'
          AND IsDeleted = 0;

        -- 4. Insert new OTP record
        SET @OtpUniqueId = NEWID();

        INSERT INTO dbo.OtpCodes (
            VerificationFlowId,
            OtpValue,
            OtpSalt,
            Status,
            ExpiresAt,
            AttemptCount,
            UniqueId,
            CreatedAt,
            UpdatedAt,
            IsDeleted
        )
        VALUES (
            @FlowId,
            @OtpHash,
            @OtpSalt,
            @Status,
            @ExpiresAt,
            0,
            @OtpUniqueId,
            GETUTCDATE(),
            GETUTCDATE(),
            0
        );

        DECLARE @OtpId BIGINT = SCOPE_IDENTITY();

        -- 5. Increment OTP count on verification flow
        UPDATE dbo.VerificationFlows
        SET OtpCount = OtpCount + 1,
            UpdatedAt = GETUTCDATE()
        WHERE Id = @FlowId;

        -- 6. Log event
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_inserted',
            @Message = 'OTP record inserted successfully',
            @EntityType = 'OtpCode',
            @EntityId = @OtpId;

        SET @Outcome = 'created';
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Log error
        EXEC dbo.SP_LogEvent
            @EventType = 'otp_insert_error',
            @Severity = 'error',
            @Message = @ErrorMessage,
            @EntityType = 'OtpCode';

        SET @Outcome = 'error';
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
