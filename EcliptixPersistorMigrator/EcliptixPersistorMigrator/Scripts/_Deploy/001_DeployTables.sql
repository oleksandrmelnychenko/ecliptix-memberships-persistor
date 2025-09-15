-- ============================================
-- Tables Deployment Script
-- Purpose: Deploys all tables in dependency order
-- Author: Oleksandr Melnychenko
-- Created: 2025-09-15
-- Dependencies: None (foundation layer)
-- ============================================

USE [EcliptixMemberships];
GO

PRINT 'Deploying Tables in dependency order...';
GO

-- Core Tables (No dependencies)
PRINT 'Deploying Core Tables...';
:r ../01_Tables/Core/001_AppDevices.sql
:r ../01_Tables/Core/002_PhoneNumbers.sql

-- Relationship Tables (Depend on Core)
PRINT 'Deploying Relationship Tables...';
:r ../01_Tables/Relationships/001_PhoneNumberDevices.sql

-- Verification Tables (Depend on Core)
PRINT 'Deploying Verification Tables...';
:r ../01_Tables/Verification/001_VerificationFlows.sql
:r ../01_Tables/Verification/002_OtpRecords.sql
:r ../01_Tables/Verification/003_FailedOtpAttempts.sql

-- Membership Tables (Depend on Core and Verification)
PRINT 'Deploying Membership Tables...';
:r ../01_Tables/Membership/001_Memberships.sql
:r ../01_Tables/Membership/002_MembershipAttempts.sql

-- Logging Tables (Independent)
PRINT 'Deploying Logging Tables...';
:r ../01_Tables/Logging/001_LoginAttempts.sql
:r ../01_Tables/Logging/002_EventLog.sql

PRINT 'All tables deployed successfully!';
GO
