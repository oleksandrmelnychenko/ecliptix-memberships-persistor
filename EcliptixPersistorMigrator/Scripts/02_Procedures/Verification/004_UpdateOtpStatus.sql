-- ============================================
-- Object: UpdateOtpStatus Procedure
-- Type: Verification Procedure
-- Purpose: Updates OTP status with state validation and flow status management
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: OtpRecords, VerificationFlows, FailedOtpAttempts tables
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.UpdateOtpStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpdateOtpStatus;
GO

-- Create UpdateOtpStatus procedure
-- Updates OTP status with proper state transitions and audit logging
CREATE PROCEDURE dbo.UpdateOtpStatus
    @OtpUniqueId UNIQUEIDENTIFIER,
    @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentStatus NVARCHAR(20), @FlowId BIGINT, @FlowUniqueId UNIQUEIDENTIFIER;

    SELECT @CurrentStatus = o.Status, @FlowId = vf.Id, @FlowUniqueId = vf.UniqueId
    FROM dbo.OtpRecords AS o
    JOIN dbo.VerificationFlows AS vf ON o.FlowUniqueId = vf.UniqueId
    WHERE o.UniqueId = @OtpUniqueId
        AND o.IsDeleted = 0
        AND vf.IsDeleted = 0
        AND vf.Status = 'pending'
        AND vf.ExpiresAt > GETUTCDATE();

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, 'OTP not found, deleted, or flow invalid/expired' AS Message;
        RETURN;
    END

    IF @CurrentStatus = 'expired' AND @NewStatus = 'pending'
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, 'Cannot transition from expired to pending' AS Message;
        RETURN;
    END

    UPDATE dbo.OtpRecords
    SET Status = @NewStatus,
        IsActive = CASE WHEN @NewStatus = 'pending' THEN 1 ELSE 0 END
    WHERE UniqueId = @OtpUniqueId AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, 'Failed to update OTP: no rows affected' AS Message;
        RETURN;
    END

    -- Handle status-specific actions
    IF @NewStatus = 'failed'
        INSERT INTO dbo.FailedOtpAttempts (OtpUniqueId, FlowUniqueId) VALUES (@OtpUniqueId, @FlowUniqueId);
    ELSE IF @NewStatus = 'verified'
        UPDATE dbo.VerificationFlows SET Status = 'verified' WHERE Id = @FlowId;

    SELECT CAST(1 AS BIT) AS Success, 'OTP status updated successfully' AS Message;
END;
GO

PRINT '✅ UpdateOtpStatus procedure created successfully';
GO