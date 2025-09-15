/*
================================================================================
V005: Verification Flow Procedures
================================================================================
Purpose: Phone verification flow management with OTP handling
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- InitiateVerificationFlow procedure
IF OBJECT_ID('dbo.InitiateVerificationFlow', 'P') IS NOT NULL DROP PROCEDURE dbo.InitiateVerificationFlow;
GO

CREATE PROCEDURE dbo.InitiateVerificationFlow
    @PhoneNumber NVARCHAR(20),
    @FlowType NVARCHAR(50) = 'PHONE_VERIFICATION',
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(7) = GETUTCDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check rate limiting
        DECLARE @MaxFlowsPerHour INT = CAST(dbo.GetConfigValue('RateLimit.MaxFlowsPerHour') AS INT);
        DECLARE @WindowHours INT = CAST(dbo.GetConfigValue('RateLimit.WindowHours') AS INT);

        DECLARE @WindowStart DATETIME2(7) = DATEADD(HOUR, -@WindowHours, GETUTCDATE());
        DECLARE @RecentFlowCount INT;

        SELECT @RecentFlowCount = COUNT(*)
        FROM dbo.VerificationFlows
        WHERE PhoneNumber = @PhoneNumber
        AND InitiatedAt >= @WindowStart;

        IF @RecentFlowCount >= @MaxFlowsPerHour
        BEGIN
            SELECT
                NULL AS FlowId,
                0 AS Success,
                'Rate limit exceeded. Too many verification attempts.' AS Message;
            RETURN;
        END

        -- Expire any existing active flows
        UPDATE dbo.VerificationFlows
        SET Status = 'EXPIRED',
            UpdatedAt = GETUTCDATE()
        WHERE PhoneNumber = @PhoneNumber
        AND Status IN ('INITIATED', 'OTP_SENT', 'VERIFYING')
        AND ExpiresAt > GETUTCDATE();

        -- Get expiration time from config
        DECLARE @ExpirationMinutes INT = CAST(dbo.GetConfigValue('VerificationFlow.DefaultExpirationMinutes') AS INT);
        DECLARE @ExpiresAt DATETIME2(7) = DATEADD(MINUTE, @ExpirationMinutes, GETUTCDATE());
        DECLARE @MaxAttempts INT = CAST(dbo.GetConfigValue('OTP.MaxAttempts') AS INT);

        -- Create new verification flow
        DECLARE @FlowId UNIQUEIDENTIFIER = NEWID();

        INSERT INTO dbo.VerificationFlows (
            FlowId, PhoneNumber, FlowType, Status,
            ExpiresAt, MaxAttempts, IpAddress, UserAgent
        )
        VALUES (
            @FlowId, @PhoneNumber, @FlowType, 'INITIATED',
            @ExpiresAt, @MaxAttempts, @IpAddress, @UserAgent
        );

        -- Log audit
        INSERT INTO dbo.AuditLog (
            EntityType, EntityId, Operation, NewValues,
            IpAddress, UserAgent, CreatedBy
        )
        VALUES (
            'VerificationFlow', CAST(@FlowId AS NVARCHAR(50)), 'INSERT',
            JSON_OBJECT('PhoneNumber', @PhoneNumber, 'FlowType', @FlowType, 'Status', 'INITIATED'),
            @IpAddress, @UserAgent, 'SYSTEM'
        );

        COMMIT TRANSACTION;

        -- Log performance
        DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
        EXEC dbo.LogPerformance
            @OperationName = 'InitiateVerificationFlow',
            @OperationType = 'INSERT',
            @ExecutionTimeMs = @Duration,
            @RowsAffected = 1,
            @Success = 1;

        SELECT
            @FlowId AS FlowId,
            @ExpiresAt AS ExpiresAt,
            1 AS Success,
            'Verification flow initiated successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        EXEC dbo.LogError
            @ProcedureName = 'InitiateVerificationFlow',
            @Parameters = JSON_OBJECT('PhoneNumber', @PhoneNumber, 'FlowType', @FlowType);

        SELECT
            NULL AS FlowId,
            NULL AS ExpiresAt,
            0 AS Success,
            ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

-- CreateOtp procedure
IF OBJECT_ID('dbo.CreateOtp', 'P') IS NOT NULL DROP PROCEDURE dbo.CreateOtp;
GO

CREATE PROCEDURE dbo.CreateOtp
    @FlowId UNIQUEIDENTIFIER,
    @CodeHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(7) = GETUTCDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verify flow is valid and active
        DECLARE @FlowStatus NVARCHAR(20);
        DECLARE @FlowExpiresAt DATETIME2(7);

        SELECT @FlowStatus = Status, @FlowExpiresAt = ExpiresAt
        FROM dbo.VerificationFlows
        WHERE FlowId = @FlowId;

        IF @FlowStatus IS NULL
        BEGIN
            SELECT 0 AS Success, 'Verification flow not found' AS Message;
            RETURN;
        END

        IF @FlowExpiresAt <= GETUTCDATE()
        BEGIN
            UPDATE dbo.VerificationFlows
            SET Status = 'EXPIRED', UpdatedAt = GETUTCDATE()
            WHERE FlowId = @FlowId;

            SELECT 0 AS Success, 'Verification flow has expired' AS Message;
            RETURN;
        END

        IF @FlowStatus NOT IN ('INITIATED', 'OTP_SENT')
        BEGIN
            SELECT 0 AS Success, 'Invalid flow status for OTP creation' AS Message;
            RETURN;
        END

        -- Get OTP configuration
        DECLARE @OtpExpirationMinutes INT = CAST(dbo.GetConfigValue('OTP.ExpirationMinutes') AS INT);
        DECLARE @MaxAttempts INT = CAST(dbo.GetConfigValue('OTP.MaxAttempts') AS INT);
        DECLARE @OtpExpiresAt DATETIME2(7) = DATEADD(MINUTE, @OtpExpirationMinutes, GETUTCDATE());

        -- Expire any existing OTPs for this flow
        UPDATE dbo.OtpCodes
        SET IsUsed = 1, UpdatedAt = GETUTCDATE()
        WHERE FlowId = @FlowId AND IsUsed = 0;

        -- Create new OTP
        DECLARE @OtpId UNIQUEIDENTIFIER = NEWID();

        INSERT INTO dbo.OtpCodes (
            OtpId, FlowId, CodeHash, ExpiresAt, MaxAttempts
        )
        VALUES (
            @OtpId, @FlowId, @CodeHash, @OtpExpiresAt, @MaxAttempts
        );

        -- Update flow status
        UPDATE dbo.VerificationFlows
        SET Status = 'OTP_SENT',
            UpdatedAt = GETUTCDATE()
        WHERE FlowId = @FlowId;

        -- Log audit
        INSERT INTO dbo.AuditLog (
            EntityType, EntityId, Operation, NewValues, CreatedBy
        )
        VALUES (
            'OtpCode', CAST(@OtpId AS NVARCHAR(50)), 'INSERT',
            JSON_OBJECT('FlowId', @FlowId, 'ExpiresAt', @OtpExpiresAt), 'SYSTEM'
        );

        COMMIT TRANSACTION;

        -- Log performance
        DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
        EXEC dbo.LogPerformance
            @OperationName = 'CreateOtp',
            @OperationType = 'INSERT',
            @ExecutionTimeMs = @Duration,
            @RowsAffected = 1,
            @Success = 1;

        SELECT
            @OtpId AS OtpId,
            @OtpExpiresAt AS ExpiresAt,
            1 AS Success,
            'OTP created successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        EXEC dbo.LogError
            @ProcedureName = 'CreateOtp',
            @Parameters = JSON_OBJECT('FlowId', @FlowId);

        SELECT
            NULL AS OtpId,
            NULL AS ExpiresAt,
            0 AS Success,
            ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

-- VerifyOtp procedure
IF OBJECT_ID('dbo.VerifyOtp', 'P') IS NOT NULL DROP PROCEDURE dbo.VerifyOtp;
GO

CREATE PROCEDURE dbo.VerifyOtp
    @FlowId UNIQUEIDENTIFIER,
    @CodeHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(7) = GETUTCDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Get the active OTP for this flow
        DECLARE @OtpId UNIQUEIDENTIFIER;
        DECLARE @OtpCodeHash NVARCHAR(255);
        DECLARE @OtpExpiresAt DATETIME2(7);
        DECLARE @AttemptCount INT;
        DECLARE @MaxAttempts INT;
        DECLARE @IsUsed BIT;

        SELECT TOP 1
            @OtpId = OtpId,
            @OtpCodeHash = CodeHash,
            @OtpExpiresAt = ExpiresAt,
            @AttemptCount = AttemptCount,
            @MaxAttempts = MaxAttempts,
            @IsUsed = IsUsed
        FROM dbo.OtpCodes
        WHERE FlowId = @FlowId AND IsUsed = 0
        ORDER BY CreatedAt DESC;

        IF @OtpId IS NULL
        BEGIN
            SELECT 0 AS Success, 'No active OTP found for this flow' AS Message;
            RETURN;
        END

        -- Check if OTP is expired
        IF @OtpExpiresAt <= GETUTCDATE()
        BEGIN
            UPDATE dbo.OtpCodes
            SET IsUsed = 1, UpdatedAt = GETUTCDATE()
            WHERE OtpId = @OtpId;

            UPDATE dbo.VerificationFlows
            SET Status = 'EXPIRED', UpdatedAt = GETUTCDATE()
            WHERE FlowId = @FlowId;

            SELECT 0 AS Success, 'OTP has expired' AS Message;
            RETURN;
        END

        -- Increment attempt count
        UPDATE dbo.OtpCodes
        SET AttemptCount = AttemptCount + 1,
            UpdatedAt = GETUTCDATE()
        WHERE OtpId = @OtpId;

        SET @AttemptCount = @AttemptCount + 1;

        -- Check if max attempts exceeded
        IF @AttemptCount > @MaxAttempts
        BEGIN
            UPDATE dbo.OtpCodes
            SET IsUsed = 1, UpdatedAt = GETUTCDATE()
            WHERE OtpId = @OtpId;

            UPDATE dbo.VerificationFlows
            SET Status = 'FAILED', FailedAt = GETUTCDATE(), UpdatedAt = GETUTCDATE()
            WHERE FlowId = @FlowId;

            SELECT 0 AS Success, 'Maximum OTP attempts exceeded' AS Message;
            RETURN;
        END

        -- Verify the code
        IF @OtpCodeHash <> @CodeHash
        BEGIN
            SELECT 0 AS Success, 'Invalid OTP code' AS Message;
            RETURN;
        END

        -- Mark OTP as used
        UPDATE dbo.OtpCodes
        SET IsUsed = 1, UsedAt = GETUTCDATE(), UpdatedAt = GETUTCDATE()
        WHERE OtpId = @OtpId;

        -- Mark flow as completed
        UPDATE dbo.VerificationFlows
        SET Status = 'COMPLETED',
            CompletedAt = GETUTCDATE(),
            UpdatedAt = GETUTCDATE()
        WHERE FlowId = @FlowId;

        -- Log successful verification
        INSERT INTO dbo.AuditLog (
            EntityType, EntityId, Operation, NewValues, CreatedBy
        )
        VALUES (
            'VerificationFlow', CAST(@FlowId AS NVARCHAR(50)), 'UPDATE',
            JSON_OBJECT('Status', 'COMPLETED', 'CompletedAt', GETUTCDATE()), 'SYSTEM'
        );

        COMMIT TRANSACTION;

        -- Log performance
        DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
        EXEC dbo.LogPerformance
            @OperationName = 'VerifyOtp',
            @OperationType = 'UPDATE',
            @ExecutionTimeMs = @Duration,
            @RowsAffected = 1,
            @Success = 1;

        SELECT
            1 AS Success,
            'OTP verified successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        EXEC dbo.LogError
            @ProcedureName = 'VerifyOtp',
            @Parameters = JSON_OBJECT('FlowId', @FlowId);

        SELECT
            0 AS Success,
            ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

PRINT 'V005: Verification Flow Procedures - Completed Successfully';
GO