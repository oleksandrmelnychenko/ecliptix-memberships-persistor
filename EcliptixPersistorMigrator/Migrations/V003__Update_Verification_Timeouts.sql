-- ============================================
-- Migration: V003 - Update Verification Timeouts
-- Purpose: Update verification session timeout from 5 minutes to 1 minute
--          and document 30-second OTP timeout requirement
-- Author: Oleksandr Melnychenko
-- Created: 2025-09-15
-- ============================================

USE [EcliptixMemberships];
GO

BEGIN TRANSACTION;
GO

-- Drop and recreate InitiateVerificationFlow with 1-minute timeout
IF OBJECT_ID('dbo.InitiateVerificationFlow', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InitiateVerificationFlow;
GO

CREATE PROCEDURE dbo.InitiateVerificationFlow
    @AppDeviceId UNIQUEIDENTIFIER,
    @PhoneUniqueId UNIQUEIDENTIFIER,
    @Purpose NVARCHAR(30),
    @ConnectionId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. Validation
    DECLARE @PhoneNumberId BIGINT;
    SELECT @PhoneNumberId = Id FROM dbo.PhoneNumbers WHERE UniqueId = @PhoneUniqueId AND IsDeleted = 0;
    IF @PhoneNumberId IS NULL
    BEGIN
        SELECT 'phone_not_found' AS Outcome;
        RETURN;
    END

    -- 2. Check for existing verified valid flow
    DECLARE @ExistingVerifiedFlowId UNIQUEIDENTIFIER;
    SELECT TOP 1 @ExistingVerifiedFlowId = UniqueId
    FROM dbo.VerificationFlows
    WHERE PhoneNumberId = @PhoneNumberId
        AND Status = 'verified'
        AND IsDeleted = 0
        AND ExpiresAt > GETUTCDATE()
    ORDER BY CreatedAt DESC;

    IF @ExistingVerifiedFlowId IS NOT NULL
    BEGIN
        SELECT *, 'verified' AS Outcome FROM dbo.GetFullFlowState(@ExistingVerifiedFlowId);
        RETURN;
    END

    -- 3. Global Rate Limiting - 30 FLOWS PER HOUR
    DECLARE @MaxFlowsPerHour INT = 30;
    IF (SELECT COUNT(*) FROM dbo.VerificationFlows WHERE PhoneNumberId = @PhoneNumberId AND CreatedAt > DATEADD(hour, -1, GETUTCDATE())) >= @MaxFlowsPerHour
    BEGIN
        SELECT 'global_rate_limit_exceeded' AS Outcome;
        RETURN;
    END

    -- 4. Deactivate old expired flows for this combination to free unique index
    UPDATE dbo.VerificationFlows
    SET Status = 'expired'
    WHERE AppDeviceId = @AppDeviceId
        AND PhoneNumberId = @PhoneNumberId
        AND Purpose = @Purpose
        AND Status = 'pending'
        AND IsDeleted = 0
        AND ExpiresAt <= GETUTCDATE();

    -- 5. Atomic "INSERT, CATCH, SELECT" approach - UPDATED TO 1 MINUTE
    DECLARE @NewFlowUniqueId UNIQUEIDENTIFIER = NEWID();
    DECLARE @ExpiresAt DATETIME2(7) = DATEADD(minute, 1, GETUTCDATE());

    BEGIN TRY
        INSERT INTO dbo.VerificationFlows (UniqueId, AppDeviceId, PhoneNumberId, Purpose, ExpiresAt, ConnectionId, OtpCount)
        VALUES (@NewFlowUniqueId, @AppDeviceId, @PhoneNumberId, @Purpose, @ExpiresAt, @ConnectionId, 0);

        SELECT *, 'created' AS Outcome FROM dbo.GetFullFlowState(@NewFlowUniqueId);
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601, 2627) -- Uniqueness violation
        BEGIN
            -- Race condition: another thread beat us. Safely get existing record.
            DECLARE @ExistingFlowId UNIQUEIDENTIFIER;
            SELECT TOP 1 @ExistingFlowId = UniqueId
            FROM dbo.VerificationFlows
            WHERE AppDeviceId = @AppDeviceId
                AND PhoneNumberId = @PhoneNumberId
                AND Purpose = @Purpose
                AND Status = 'pending'
                AND IsDeleted = 0
                AND ExpiresAt > GETUTCDATE()
            ORDER BY CreatedAt DESC;

            IF @ExistingFlowId IS NOT NULL
                SELECT *, 'retrieved' AS Outcome FROM dbo.GetFullFlowState(@ExistingFlowId);
            ELSE
                SELECT 'conflict_unresolved' AS Outcome;
        END
        ELSE
            THROW;
    END CATCH;
END;
GO

COMMIT TRANSACTION;
GO

PRINT '✅ V003: Verification timeouts updated successfully';
PRINT '   - Verification session timeout: 5 minutes → 1 minute';
PRINT '   - Note: OTP timeout should be set to 30 seconds by application';
GO