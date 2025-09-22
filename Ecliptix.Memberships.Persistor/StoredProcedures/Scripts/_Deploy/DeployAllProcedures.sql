-- ============================================================================
-- Deploy All Stored Procedures
-- ============================================================================
-- Purpose: Deploys all stored procedures in the correct order
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

USE [EcliptixMemberships];
GO

SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '🚀 Starting stored procedures deployment...';
GO

-- ============================================================================
-- 1. UTILITIES (Base dependencies)
-- ============================================================================
PRINT '📋 Deploying utility procedures...';
GO

-- SP_LogEvent
:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Utilities/SP_LogEvent.sql
GO

-- ============================================================================
-- 2. CORE PROCEDURES (Basic operations)
-- ============================================================================
PRINT '🔧 Deploying core procedures...';
GO

-- SP_EnsurePhoneNumber
:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Core/SP_EnsurePhoneNumber.sql
GO

-- SP_RegisterAppDevice
:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Core/SP_RegisterAppDevice.sql
GO

-- ============================================================================
-- 3. MEMBERSHIP PROCEDURES (Business logic)
-- ============================================================================

-- SP_CreateMembership
PRINT '👥 Deploying membership procedures...';
GO

:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Membership/SP_CreateMembership.sql
GO

-- ============================================================================
-- 4. VERIFICATION PROCEDURES (Business logic)
-- ============================================================================
PRINT '🔐 Deploying verification procedures...';
GO

-- SP_InitiateVerificationFlow
:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Verification/SP_InitiateVerificationFlow.sql
GO

-- SP_GenerateOtpCode
:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Verification/SP_GenerateOtpCode.sql
GO

-- SP_VerifyOtpCode
:r Ecliptix.Memberships.Persistor/StoredProcedures/Scripts/Verification/SP_VerifyOtpCode.sql
GO

-- ============================================================================
-- 5. VERIFICATION AND TESTING
-- ============================================================================
PRINT '✅ Verifying stored procedures deployment...';
GO

-- Check if all procedures exist
IF OBJECT_ID('dbo.SP_LogEvent', 'P') IS NULL
    RAISERROR('SP_LogEvent not found', 16, 1);

IF OBJECT_ID('dbo.SP_EnsurePhoneNumber', 'P') IS NULL
    RAISERROR('SP_EnsurePhoneNumber not found', 16, 1);

IF OBJECT_ID('dbo.SP_RegisterAppDevice', 'P') IS NULL
    RAISERROR('SP_RegisterAppDevice not found', 16, 1);

IF OBJECT_ID('dbo.SP_InitiateVerificationFlow', 'P') IS NULL
    RAISERROR('SP_InitiateVerificationFlow not found', 16, 1);

IF OBJECT_ID('dbo.SP_GenerateOtpCode', 'P') IS NULL
    RAISERROR('SP_GenerateOtpCode not found', 16, 1);

IF OBJECT_ID('dbo.SP_VerifyOtpCode', 'P') IS NULL
    RAISERROR('SP_VerifyOtpCode not found', 16, 1);

IF OBJECT_ID('dbo.SP_CreateMembership', 'P') IS NULL
    RAISERROR('SP_CreateMembership not found', 16, 1);

PRINT '✅ All stored procedures deployed successfully!';

-- Log deployment
EXEC dbo.SP_LogEvent
    @EventType = 'stored_procedures_deployed',
    @Severity = 'info',
    @Message = 'All stored procedures deployed successfully',
    @EntityType = 'System';

GO