-- ============================================
-- Object: GetPhoneNumber Function (Verification Enhanced)
-- Type: Inline Table-Valued Function
-- Purpose: Enhanced phone number retrieval with UniqueId included for verification workflows
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers table
-- Note: This is an enhanced version that includes UniqueId in output
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing function if exists (for clean deployment)
IF OBJECT_ID('dbo.GetPhoneNumber', 'IF') IS NOT NULL
    DROP FUNCTION dbo.GetPhoneNumber;
GO

-- Create GetPhoneNumber inline table-valued function (verification enhanced)
-- Returns phone number, region, and UniqueId for verification workflows
CREATE FUNCTION dbo.GetPhoneNumber (@PhoneUniqueId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
(
    SELECT
        pn.PhoneNumber,
        pn.Region,
        pn.UniqueId
    FROM dbo.PhoneNumbers AS pn
    WHERE pn.UniqueId = @PhoneUniqueId
      AND pn.IsDeleted = 0
);
GO

PRINT '✅ GetPhoneNumber (verification enhanced) function created successfully';
GO