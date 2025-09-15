-- ============================================
-- Object: TRG_PhoneNumberDevices_Update Trigger
-- Type: UpdatedAt Trigger
-- Purpose: Automatically updates UpdatedAt field when PhoneNumberDevices records are modified
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumberDevices table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing trigger if exists (for clean deployment)
IF OBJECT_ID('dbo.TRG_PhoneNumberDevices_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_PhoneNumberDevices_Update;
GO

-- Create UpdatedAt trigger for PhoneNumberDevices table
-- Automatically updates UpdatedAt field when records are modified
-- Note: Uses composite primary key for JOIN
CREATE TRIGGER TRG_PhoneNumberDevices_Update ON dbo.PhoneNumberDevices FOR UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(UpdatedAt) RETURN; -- Prevent recursion
    UPDATE t SET UpdatedAt = GETUTCDATE()
    FROM dbo.PhoneNumberDevices t
    INNER JOIN inserted i ON t.PhoneNumberId = i.PhoneNumberId AND t.AppDeviceId = i.AppDeviceId;
END;
GO

PRINT '✅ TRG_PhoneNumberDevices_Update trigger created successfully';
GO