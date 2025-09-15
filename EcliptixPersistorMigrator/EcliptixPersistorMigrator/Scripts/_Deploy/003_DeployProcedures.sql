-- ============================================
-- Procedures Deployment Script  
-- Purpose: Deploys all procedures in dependency order
-- Author: Oleksandr Melnychenko
-- Created: 2025-09-15
-- Dependencies: Tables and Functions must be deployed first
-- ============================================

USE [EcliptixMemberships];
GO

PRINT 'Deploying Procedures in dependency order...';
GO

-- Core Procedures (Foundation layer)
PRINT 'Deploying Core Procedures...';
:r ../02_Procedures/Core/001_RegisterAppDeviceIfNotExists.sql
:r ../02_Procedures/Core/002_EnsurePhoneNumber.sql
:r ../02_Procedures/Core/003_VerifyPhoneForSecretKeyRecovery.sql

-- Membership Logging Procedures (Required by other membership procedures)
PRINT 'Deploying Membership Logging Procedures...';
:r ../02_Procedures/Membership/001_LogLoginAttempt.sql
:r ../02_Procedures/Membership/002_LogMembershipAttempt.sql

-- Verification Procedures (Depend on core and functions)
PRINT 'Deploying Verification Procedures...';
:r ../02_Procedures/Verification/001_InitiateVerificationFlow.sql
:r ../02_Procedures/Verification/002_RequestResendOtp.sql
:r ../02_Procedures/Verification/003_InsertOtpRecord.sql
:r ../02_Procedures/Verification/004_UpdateOtpStatus.sql
:r ../02_Procedures/Verification/005_UpdateVerificationFlowStatus.sql
:r ../02_Procedures/Verification/006_ExpireAssociatedOtp.sql

-- Membership Procedures (Depend on logging procedures)
PRINT 'Deploying Membership Management Procedures...';
:r ../02_Procedures/Membership/003_CreateMembership.sql
:r ../02_Procedures/Membership/004_UpdateMembershipSecureKey.sql
:r ../02_Procedures/Membership/005_LoginMembership.sql

PRINT 'All procedures deployed successfully!';
GO
