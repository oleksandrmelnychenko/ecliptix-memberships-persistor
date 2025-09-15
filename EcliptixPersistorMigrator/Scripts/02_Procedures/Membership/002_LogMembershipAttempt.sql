-- ============================================
-- Object: LogMembershipAttempt Procedure
-- Type: Membership Procedure (Logging)
-- Purpose: Logs membership creation attempts for analytics and rate limiting
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: MembershipAttempts table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.LogMembershipAttempt', 'P') IS NOT NULL
    DROP PROCEDURE dbo.LogMembershipAttempt;
GO

-- Create LogMembershipAttempt procedure
-- Logs all membership creation attempts for rate limiting and analytics
CREATE PROCEDURE dbo.LogMembershipAttempt
    @PhoneNumberId UNIQUEIDENTIFIER,
    @Outcome NVARCHAR(MAX),
    @IsSuccess BIT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.MembershipAttempts (PhoneNumberId, Timestamp, Outcome, IsSuccess)
    VALUES (@PhoneNumberId, GETUTCDATE(), @Outcome, @IsSuccess);
END;
GO

PRINT '✅ LogMembershipAttempt procedure created successfully';
GO