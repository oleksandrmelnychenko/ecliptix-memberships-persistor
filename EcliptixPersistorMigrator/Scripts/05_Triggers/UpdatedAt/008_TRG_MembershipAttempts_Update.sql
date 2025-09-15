-- ============================================
-- Object: TRG_MembershipAttempts_Update Trigger
-- Type: UpdatedAt Trigger
-- Purpose: Automatically updates UpdatedAt field when MembershipAttempts records are modified
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: MembershipAttempts table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing trigger if exists (for clean deployment)
IF OBJECT_ID('dbo.TRG_MembershipAttempts_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_MembershipAttempts_Update;
GO

-- Create UpdatedAt trigger for MembershipAttempts table
-- Automatically updates UpdatedAt field when records are modified
CREATE TRIGGER TRG_MembershipAttempts_Update ON dbo.MembershipAttempts FOR UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN; -- Prevent recursion
    UPDATE t SET UpdatedAt = GETUTCDATE()
    FROM dbo.MembershipAttempts t
    INNER JOIN inserted i ON t.Id = i.Id;
END;
GO

PRINT '✅ TRG_MembershipAttempts_Update trigger created successfully';
GO