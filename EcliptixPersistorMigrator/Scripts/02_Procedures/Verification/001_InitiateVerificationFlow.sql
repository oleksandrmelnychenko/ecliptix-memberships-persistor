-- ============================================
-- Object: InitiateVerificationFlow Procedure
-- Type: Verification Procedure
-- Purpose: Main entry point for verification flow creation with race-condition protection
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script, updated to 30 flows/hour
-- Dependencies: VerificationFlows, PhoneNumbers, GetFullFlowState function
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.InitiateVerificationFlow', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InitiateVerificationFlow;
GO

-- Create InitiateVerificationFlow procedure
-- Atomically retrieves existing active flow OR creates a new one
-- Single entry point for verification initiation
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

    -- 3. Global Rate Limiting - UPDATED TO 30 FLOWS PER HOUR
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

    -- 5. Atomic "INSERT, CATCH, SELECT" approach
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

PRINT '✅ InitiateVerificationFlow procedure created successfully';
GO