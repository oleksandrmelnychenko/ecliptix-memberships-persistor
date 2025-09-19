-- ============================================================================
-- SP_InitiateVerificationFlow - Start phone verification process
-- ============================================================================
-- Purpose: Initiates a new verification flow with rate limiting and validation
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_InitiateVerificationFlow
    @PhoneNumber NVARCHAR(18),
    @Region NVARCHAR(2),
    @AppDeviceId UNIQUEIDENTIFIER,
    @Purpose NVARCHAR(30) = 'unspecified',
    @ConnectionId BIGINT = NULL,
    @FlowUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PhoneNumberId BIGINT;
    DECLARE @DeviceRecordId BIGINT;
    DECLARE @FlowId BIGINT;

    SET @Outcome = 'error';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Ensure phone number exists
        DECLARE @PhoneUniqueId UNIQUEIDENTIFIER;
        DECLARE @IsPhoneNewlyCreated BIT;

        EXEC dbo.SP_EnsurePhoneNumber
            @PhoneNumber = @PhoneNumber,
            @Region = @Region,
            @PhoneNumberId = @PhoneNumberId OUTPUT,
            @UniqueId = @PhoneUniqueId OUTPUT,
            @IsNewlyCreated = @IsPhoneNewlyCreated OUTPUT;

        -- 2. Validate device exists
        SELECT @DeviceRecordId = Id
        FROM dbo.Devices
        WHERE UniqueId = @AppDeviceId
          AND IsDeleted = 0;

        IF @DeviceRecordId IS NULL
        BEGIN
            SET @Outcome = 'device_not_found';
            SET @ErrorMessage = 'Application device not registered';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Check for existing active flow
        IF EXISTS (
            SELECT 1 FROM dbo.VerificationFlows
            WHERE AppDeviceId = @AppDeviceId
              AND PhoneNumberId = @PhoneNumberId
              AND Purpose = @Purpose
              AND Status = 'pending'
              AND ExpiresAt > GETUTCDATE()
              AND IsDeleted = 0
        )
        BEGIN
            SET @Outcome = 'active_flow_exists';
            SET @ErrorMessage = 'Active verification flow already exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 4. Rate limiting - 30 flows per hour per phone number
        DECLARE @MaxFlowsPerHour INT = 30;
        DECLARE @RecentFlowCount INT;

        SELECT @RecentFlowCount = COUNT(*)
        FROM dbo.VerificationFlows
        WHERE PhoneNumberId = @PhoneNumberId
          AND CreatedAt > DATEADD(hour, -1, GETUTCDATE());

        IF @RecentFlowCount >= @MaxFlowsPerHour
        BEGIN
            SET @Outcome = 'rate_limit_exceeded';
            SET @ErrorMessage = 'Too many verification attempts. Please try again later.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 5. Device-specific rate limiting - 10 flows per hour per device
        DECLARE @MaxDeviceFlowsPerHour INT = 10;
        DECLARE @RecentDeviceFlowCount INT;

        SELECT @RecentDeviceFlowCount = COUNT(*)
        FROM dbo.VerificationFlows
        WHERE AppDeviceId = @AppDeviceId
          AND CreatedAt > DATEADD(hour, -1, GETUTCDATE());

        IF @RecentDeviceFlowCount >= @MaxDeviceFlowsPerHour
        BEGIN
            SET @Outcome = 'device_rate_limit_exceeded';
            SET @ErrorMessage = 'Too many verification attempts from this device.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 6. Create new verification flow
        SET @FlowUniqueId = NEWID();

        INSERT INTO dbo.VerificationFlows (
            PhoneNumberId, AppDeviceId, Status, Purpose, ExpiresAt,
            OtpCount, ConnectionId, UniqueId, CreatedAt, UpdatedAt
        )
        VALUES (
            @PhoneNumberId, @AppDeviceId, 'pending', @Purpose,
            DATEADD(minute, 15, GETUTCDATE()), 0, @ConnectionId, @FlowUniqueId,
            GETUTCDATE(), GETUTCDATE()
        );

        SET @FlowId = SCOPE_IDENTITY();

        -- 7. Log the initiation
        EXEC dbo.SP_LogEvent
            @EventType = 'verification_flow_initiated',
            @Message = 'Verification flow started',
            @EntityType = 'VerificationFlow',
            @EntityId = @FlowId;

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
            @EventType = 'verification_flow_error',
            @Severity = 'error',
            @Message = 'Failed to initiate verification flow',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO