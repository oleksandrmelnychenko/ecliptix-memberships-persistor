-- ============================================
-- Object: GetPhoneNumber Function
-- Type: Inline Table-Valued Function
-- Purpose: Retrieves phone number details by UniqueId
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing function if exists (for clean deployment)
IF OBJECT_ID('dbo.GetPhoneNumber', 'IF') IS NOT NULL
    DROP FUNCTION dbo.GetPhoneNumber;
GO

-- Create GetPhoneNumber inline table-valued function
-- Retrieves phone number and region details for a given UniqueId
CREATE FUNCTION dbo.GetPhoneNumber
(
    @UniqueId UNIQUEIDENTIFIER
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        pn.PhoneNumber,
        pn.Region
    FROM dbo.PhoneNumbers AS pn
    WHERE pn.UniqueId = @UniqueId
      AND pn.IsDeleted = 0
);
GO

PRINT '✅ GetPhoneNumber function created successfully';
GO