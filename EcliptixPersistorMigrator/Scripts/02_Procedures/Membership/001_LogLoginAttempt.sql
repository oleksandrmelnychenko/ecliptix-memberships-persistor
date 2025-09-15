-- ============================================
-- Object: LogLoginAttempt Procedure
-- Type: Membership Procedure (Logging)
-- Purpose: Logs login attempts for security monitoring and lockout management
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: LoginAttempts table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.LogLoginAttempt', 'P') IS NOT NULL
    DROP PROCEDURE dbo.LogLoginAttempt;
GO

-- Create LogLoginAttempt procedure
-- Logs all login attempts with outcome and success status for security monitoring
CREATE PROCEDURE dbo.LogLoginAttempt
    @PhoneNumber NVARCHAR(18),
    @Outcome NVARCHAR(MAX),
    @IsSuccess BIT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.LoginAttempts (Timestamp, PhoneNumber, Outcome, IsSuccess)
    VALUES (GETUTCDATE(), @PhoneNumber, @Outcome, @IsSuccess);
END;
GO

PRINT '✅ LogLoginAttempt procedure created successfully';
GO