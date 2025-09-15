-- ============================================
-- Object: ExpireAssociatedOtp Procedure
-- Type: Verification Procedure
-- Purpose: Expires all pending OTP records associated with a verification flow
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: OtpRecords table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.ExpireAssociatedOtp', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ExpireAssociatedOtp;
GO

-- Create ExpireAssociatedOtp procedure
-- Sets status "expired" for all "pending" OTPs associated with a flow
CREATE PROCEDURE dbo.ExpireAssociatedOtp
    @FlowUniqueId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Update all pending OTP records for this flow to expired
    UPDATE dbo.OtpRecords
    SET Status = 'expired',
        IsActive = 0
    WHERE FlowUniqueId = @FlowUniqueId
        AND Status = 'pending'
        AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS OtpsExpired;
END;
GO

PRINT '✅ ExpireAssociatedOtp procedure created successfully';
GO