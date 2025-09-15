-- ============================================
-- Triggers Deployment Script
-- Purpose: Deploys all triggers in logical order
-- Author: Oleksandr Melnychenko
-- Created: 2025-09-15
-- Dependencies: Tables must be deployed first
-- ============================================

USE [EcliptixMemberships];
GO

PRINT 'Deploying Triggers...';
GO

-- UpdatedAt Triggers (Automatic timestamp management)
PRINT 'Deploying UpdatedAt Triggers...';
:r ../05_Triggers/UpdatedAt/001_TRG_AppDevices_Update.sql
:r ../05_Triggers/UpdatedAt/002_TRG_PhoneNumbers_Update.sql
:r ../05_Triggers/UpdatedAt/003_TRG_PhoneNumberDevices_Update.sql
:r ../05_Triggers/UpdatedAt/004_TRG_VerificationFlows_Update.sql
:r ../05_Triggers/UpdatedAt/005_TRG_OtpRecords_Update.sql
:r ../05_Triggers/UpdatedAt/006_TRG_FailedOtpAttempts_Update.sql
:r ../05_Triggers/UpdatedAt/007_TRG_Memberships_Update.sql
:r ../05_Triggers/UpdatedAt/008_TRG_MembershipAttempts_Update.sql
:r ../05_Triggers/UpdatedAt/009_TRG_LoginAttempts_Update.sql

PRINT 'All triggers deployed successfully!';
GO
