-- ============================================
-- Object: GetFullFlowState Function
-- Type: Inline Table-Valued Function
-- Purpose: Returns comprehensive verification flow state with active OTP information
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: VerificationFlows, PhoneNumbers, OtpRecords tables
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing function if exists (for clean deployment)
IF OBJECT_ID('dbo.GetFullFlowState', 'IF') IS NOT NULL
    DROP FUNCTION dbo.GetFullFlowState;
GO

-- Create GetFullFlowState inline table-valued function
-- Returns complete verification flow state with active OTP details
CREATE FUNCTION dbo.GetFullFlowState(@FlowUniqueId UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
(
    SELECT
        vf.UniqueId         AS UniqueIdentifier,
        pn.UniqueId         AS PhoneNumberIdentifier,
        vf.AppDeviceId      AS AppDeviceIdentifier,
        vf.ConnectionId     AS ConnectId,
        vf.ExpiresAt,
        vf.Status,
        vf.Purpose,
        vf.OtpCount,
        o.UniqueId          AS Otp_UniqueIdentifier,
        o.FlowUniqueId      AS Otp_FlowUniqueId,
        o.OtpHash           AS Otp_OtpHash,
        o.OtpSalt           AS Otp_OtpSalt,
        o.ExpiresAt         AS Otp_ExpiresAt,
        o.Status            AS Otp_Status,
        o.IsActive          AS Otp_IsActive
    FROM dbo.VerificationFlows AS vf
    JOIN dbo.PhoneNumbers AS pn ON vf.PhoneNumberId = pn.Id
    LEFT JOIN dbo.OtpRecords AS o ON o.FlowUniqueId = vf.UniqueId
        AND o.IsActive = 1
        AND o.IsDeleted = 0
        AND o.ExpiresAt > GETUTCDATE()
    WHERE vf.UniqueId = @FlowUniqueId
);
GO

PRINT '✅ GetFullFlowState function created successfully';
GO