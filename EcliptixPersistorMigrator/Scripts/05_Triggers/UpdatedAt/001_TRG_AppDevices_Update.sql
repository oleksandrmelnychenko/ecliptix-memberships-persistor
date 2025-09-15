-- ============================================
-- Object: TRG_AppDevices_Update Trigger
-- Type: UpdatedAt Trigger
-- Purpose: Automatically updates UpdatedAt field when AppDevices records are modified
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: AppDevices table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing trigger if exists (for clean deployment)
IF OBJECT_ID('dbo.TRG_AppDevices_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_AppDevices_Update;
GO

-- Create UpdatedAt trigger for AppDevices table
-- Automatically updates UpdatedAt field when records are modified
CREATE TRIGGER TRG_AppDevices_Update ON dbo.AppDevices FOR UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN; -- Prevent recursion
    UPDATE t SET UpdatedAt = GETUTCDATE()
    FROM dbo.AppDevices t
    INNER JOIN inserted i ON t.Id = i.Id;
END;
GO

PRINT '✅ TRG_AppDevices_Update trigger created successfully';
GO