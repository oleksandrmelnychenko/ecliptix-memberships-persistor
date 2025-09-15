-- ============================================
-- Object: InsertOtpRecord Procedure
-- Type: Verification Procedure
-- Purpose: Creates new OTP record with counter increment and limit protection
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script, updated OTP timeout documentation
-- Dependencies: VerificationFlows, OtpRecords tables
-- Note: @ExpiresAt should be set to 30 seconds from creation time (DATEADD(second, 30, GETUTCDATE()))
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.InsertOtpRecord', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InsertOtpRecord;
GO

-- Create InsertOtpRecord procedure
-- Creates new OTP record with proper validation and counter management
CREATE PROCEDURE dbo.InsertOtpRecord
    @FlowUniqueId UNIQUEIDENTIFIER,
    @OtpHash NVARCHAR(MAX),
    @OtpSalt NVARCHAR(MAX),
    @ExpiresAt DATETIME2(7),
    @Status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FlowId BIGINT, @PhoneNumberId BIGINT, @OtpCount SMALLINT;

    SELECT @FlowId = Id, @PhoneNumberId = PhoneNumberId, @OtpCount = OtpCount
    FROM dbo.VerificationFlows
    WHERE UniqueId = @FlowUniqueId
        AND Status = 'pending'
        AND IsDeleted = 0
        AND ExpiresAt > GETUTCDATE();

    IF @FlowId IS NULL
    BEGIN
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS OtpUniqueId, 'flow_not_found_or_invalid' AS Outcome;
        RETURN;
    END

    -- Protection against exceeding attempt limit at insert level
    IF @OtpCount >= 5
    BEGIN
        UPDATE dbo.VerificationFlows SET Status = 'failed' WHERE Id = @FlowId;
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS OtpUniqueId, 'max_otp_attempts_reached' AS Outcome;
        RETURN;
    END

    DECLARE @OtpOutputTable TABLE (UniqueId UNIQUEIDENTIFIER);
    INSERT INTO dbo.OtpRecords (FlowUniqueId, PhoneNumberId, OtpHash, OtpSalt, ExpiresAt, Status, IsActive)
    OUTPUT inserted.UniqueId INTO @OtpOutputTable(UniqueId)
    VALUES (@FlowUniqueId, @PhoneNumberId, @OtpHash, @OtpSalt, @ExpiresAt, @Status, 1);

    UPDATE dbo.VerificationFlows SET OtpCount = OtpCount + 1 WHERE Id = @FlowId;

    SELECT UniqueId AS OtpUniqueId, 'created' AS Outcome FROM @OtpOutputTable;
END;
GO

PRINT '✅ InsertOtpRecord procedure created successfully';
GO