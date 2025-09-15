-- ============================================
-- Object: RequestResendOtp Procedure
-- Type: Verification Procedure
-- Purpose: Validates all business rules for OTP resend requests with rate limiting
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: VerificationFlows, OtpRecords tables
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.RequestResendOtp', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RequestResendOtp;
GO

-- Create RequestResendOtp procedure
-- Validates all business rules for OTP resend functionality
CREATE PROCEDURE dbo.RequestResendOtp
    @FlowUniqueId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Outcome NVARCHAR(50);
    DECLARE @MaxOtpAttempts INT = 5;
    DECLARE @MinResendIntervalSeconds INT = 30;
    DECLARE @OtpCount SMALLINT;
    DECLARE @SessionExpiresAt DATETIME2(7);
    DECLARE @LastOtpTimestamp DATETIME2(7);
    DECLARE @CurrentTime DATETIME2(7) = GETUTCDATE();

    -- Step 1: Get verification flow data
    SELECT
        @OtpCount = OtpCount,
        @SessionExpiresAt = ExpiresAt
    FROM dbo.VerificationFlows
    WHERE UniqueId = @FlowUniqueId AND IsDeleted = 0 AND Status = 'pending';

    -- If flow not found or inactive, exit immediately
    IF @SessionExpiresAt IS NULL
    BEGIN
        SET @Outcome = 'flow_not_found_or_invalid';
        SELECT @Outcome AS Outcome;
        RETURN;
    END

    -- Step 2: Get timestamp of last created OTP for this flow
    SELECT @LastOtpTimestamp = MAX(CreatedAt)
    FROM dbo.OtpRecords
    WHERE FlowUniqueId = @FlowUniqueId;

    -- Step 3: Execute all business rule checks sequentially
    IF @CurrentTime >= @SessionExpiresAt
    BEGIN
        UPDATE dbo.VerificationFlows SET Status = 'expired' WHERE UniqueId = @FlowUniqueId;
        SET @Outcome = 'flow_expired';
    END
    ELSE IF @OtpCount >= @MaxOtpAttempts
    BEGIN
        UPDATE dbo.VerificationFlows SET Status = 'failed' WHERE UniqueId = @FlowUniqueId;
        SET @Outcome = 'max_otp_attempts_reached';
    END
    ELSE IF @LastOtpTimestamp IS NOT NULL AND DATEDIFF(second, @LastOtpTimestamp, @CurrentTime) < @MinResendIntervalSeconds
    BEGIN
        SET @Outcome = 'resend_cooldown_active';
    END
    ELSE
    BEGIN
        SET @Outcome = 'resend_allowed';
    END

    -- Return final result
    SELECT @Outcome AS Outcome;
END;
GO

PRINT '✅ RequestResendOtp procedure created successfully';
GO