-- ============================================
-- Object: TRG_FailedOtpAttempts_Update Trigger
-- Type: UpdatedAt Trigger
-- Purpose: Automatically updates UpdatedAt field when FailedOtpAttempts records are modified
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: FailedOtpAttempts table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing trigger if exists (for clean deployment)
IF OBJECT_ID('dbo.TRG_FailedOtpAttempts_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_FailedOtpAttempts_Update;
GO

-- Create UpdatedAt trigger for FailedOtpAttempts table
-- Automatically updates UpdatedAt field when records are modified
CREATE TRIGGER TRG_FailedOtpAttempts_Update ON dbo.FailedOtpAttempts FOR UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN; -- Prevent recursion
    UPDATE t SET UpdatedAt = GETUTCDATE()
    FROM dbo.FailedOtpAttempts t
    INNER JOIN inserted i ON t.Id = i.Id;
END;
GO

PRINT '✅ TRG_FailedOtpAttempts_Update trigger created successfully';
GO