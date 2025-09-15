-- ============================================
-- Database Status Check Script
-- Purpose: Comprehensive health check of EcliptixMemberships database
-- Author: Oleksandr Melnychenko
-- Created: 2025-09-15
-- Dependencies: All database objects
-- ============================================

USE [EcliptixMemberships];
GO

PRINT '🔍 EcliptixMemberships Database Status Report';
PRINT 'Generated: ' + CONVERT(NVARCHAR(30), GETUTCDATE(), 127);
PRINT '================================================';
GO

-- Table Status
PRINT '';
PRINT '📊 TABLE STATUS:';
SELECT 
    t.name AS TableName,
    p.rows AS RowCount,
    CASE WHEN t.is_disabled = 0 THEN '✅ Active' ELSE '❌ Disabled' END AS Status
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
    AND t.name IN ('AppDevices', 'PhoneNumbers', 'PhoneNumberDevices', 
                   'VerificationFlows', 'OtpRecords', 'FailedOtpAttempts',
                   'Memberships', 'MembershipAttempts', 'LoginAttempts', 'EventLog')
ORDER BY t.name;

-- Function Status
PRINT '';
PRINT '⚡ FUNCTION STATUS:';
SELECT 
    name AS FunctionName,
    type_desc AS Type,
    CASE WHEN is_disabled = 0 THEN '✅ Active' ELSE '❌ Disabled' END AS Status
FROM sys.objects
WHERE type IN ('IF', 'FN', 'TF')
    AND name IN ('GetPhoneNumber', 'GetFullFlowState')
ORDER BY name;

-- Procedure Status  
PRINT '';
PRINT '🔧 PROCEDURE STATUS:';
SELECT 
    name AS ProcedureName,
    CASE WHEN is_disabled = 0 THEN '✅ Active' ELSE '❌ Disabled' END AS Status
FROM sys.procedures
WHERE name IN ('RegisterAppDeviceIfNotExists', 'EnsurePhoneNumber', 'VerifyPhoneForSecretKeyRecovery',
               'InitiateVerificationFlow', 'RequestResendOtp', 'InsertOtpRecord', 
               'UpdateOtpStatus', 'UpdateVerificationFlowStatus', 'ExpireAssociatedOtp',
               'LogLoginAttempt', 'LogMembershipAttempt', 'CreateMembership', 
               'UpdateMembershipSecureKey', 'LoginMembership')
ORDER BY name;

-- Trigger Status
PRINT '';
PRINT '⚡ TRIGGER STATUS:';  
SELECT 
    name AS TriggerName,
    OBJECT_NAME(parent_object_id) AS TableName,
    CASE WHEN is_disabled = 0 THEN '✅ Active' ELSE '❌ Disabled' END AS Status
FROM sys.triggers
WHERE name LIKE 'TRG_%_Update'
ORDER BY OBJECT_NAME(parent_object_id);

-- Recent Activity Summary
PRINT '';
PRINT '📈 RECENT ACTIVITY (Last 24 Hours):';
PRINT 'Verification Flows Created: ' + CAST((SELECT COUNT(*) FROM VerificationFlows WHERE CreatedAt > DATEADD(day, -1, GETUTCDATE())) AS NVARCHAR(10));
PRINT 'OTP Records Generated: ' + CAST((SELECT COUNT(*) FROM OtpRecords WHERE CreatedAt > DATEADD(day, -1, GETUTCDATE())) AS NVARCHAR(10));
PRINT 'Memberships Created: ' + CAST((SELECT COUNT(*) FROM Memberships WHERE CreatedAt > DATEADD(day, -1, GETUTCDATE())) AS NVARCHAR(10));
PRINT 'Login Attempts: ' + CAST((SELECT COUNT(*) FROM LoginAttempts WHERE CreatedAt > DATEADD(day, -1, GETUTCDATE())) AS NVARCHAR(10));

PRINT '';
PRINT '✅ Status check completed successfully!';
GO
