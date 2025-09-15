/*
================================================================================
V006: Create Missing Tables (Safe Migration)
================================================================================
Purpose: Create only missing tables without dropping existing ones
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Create Members table only if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Members' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Members (
        MemberId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        PhoneNumber NVARCHAR(20) NOT NULL UNIQUE,
        IsActive BIT NOT NULL DEFAULT 1,
        IsVerified BIT NOT NULL DEFAULT 0,
        VerificationDate DATETIME2(7) NULL,
        IsLocked BIT NOT NULL DEFAULT 0,
        LockoutEndTime DATETIME2(7) NULL,
        FailedAuthAttempts INT NOT NULL DEFAULT 0,
        LastAuthAttempt DATETIME2(7) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER
    );

    CREATE NONCLUSTERED INDEX IX_Members_PhoneNumber ON dbo.Members (PhoneNumber);
    CREATE NONCLUSTERED INDEX IX_Members_IsActive ON dbo.Members (IsActive);
    CREATE NONCLUSTERED INDEX IX_Members_IsVerified ON dbo.Members (IsVerified);
    CREATE NONCLUSTERED INDEX IX_Members_CreatedAt ON dbo.Members (CreatedAt);

    PRINT '✓ Members table created';
END
ELSE
BEGIN
    PRINT '✓ Members table already exists';
END

-- Create AuthenticationContexts table only if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuthenticationContexts' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.AuthenticationContexts (
        ContextId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        MemberId UNIQUEIDENTIFIER NOT NULL,
        DeviceIdentifier NVARCHAR(255) NULL,
        IpAddress NVARCHAR(45) NULL,
        UserAgent NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        ExpiresAt DATETIME2(7) NOT NULL,
        LastAccessedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER
    );

    CREATE NONCLUSTERED INDEX IX_AuthenticationContexts_MemberId ON dbo.AuthenticationContexts (MemberId);
    CREATE NONCLUSTERED INDEX IX_AuthenticationContexts_IsActive ON dbo.AuthenticationContexts (IsActive);
    CREATE NONCLUSTERED INDEX IX_AuthenticationContexts_ExpiresAt ON dbo.AuthenticationContexts (ExpiresAt);

    PRINT '✓ AuthenticationContexts table created';
END
ELSE
BEGIN
    PRINT '✓ AuthenticationContexts table already exists';
END

-- Create RateLimitTracking table only if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RateLimitTracking' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.RateLimitTracking (
        TrackingId BIGINT IDENTITY(1,1) PRIMARY KEY,
        ResourceKey NVARCHAR(255) NOT NULL,
        WindowStart DATETIME2(7) NOT NULL,
        WindowEnd DATETIME2(7) NOT NULL,
        RequestCount INT NOT NULL DEFAULT 1,
        MaxRequests INT NOT NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
    );

    CREATE UNIQUE NONCLUSTERED INDEX IX_RateLimitTracking_ResourceKey_Window
        ON dbo.RateLimitTracking (ResourceKey, WindowStart);
    CREATE NONCLUSTERED INDEX IX_RateLimitTracking_WindowEnd ON dbo.RateLimitTracking (WindowEnd);

    PRINT '✓ RateLimitTracking table created';
END
ELSE
BEGIN
    PRINT '✓ RateLimitTracking table already exists';
END

-- Add foreign key constraints only if they don't exist
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AuthenticationContexts_Members')
    AND EXISTS (SELECT * FROM sys.tables WHERE name = 'Members' AND schema_id = SCHEMA_ID('dbo'))
    AND EXISTS (SELECT * FROM sys.tables WHERE name = 'AuthenticationContexts' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    ALTER TABLE dbo.AuthenticationContexts
    ADD CONSTRAINT FK_AuthenticationContexts_Members
        FOREIGN KEY (MemberId) REFERENCES dbo.Members(MemberId)
        ON DELETE CASCADE;
    PRINT '✓ FK_AuthenticationContexts_Members constraint added';
END

-- Add OtpCodes foreign key constraint only if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_OtpCodes_VerificationFlows')
    AND EXISTS (SELECT * FROM sys.tables WHERE name = 'VerificationFlows' AND schema_id = SCHEMA_ID('dbo'))
    AND EXISTS (SELECT * FROM sys.tables WHERE name = 'OtpCodes' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    ALTER TABLE dbo.OtpCodes
    ADD CONSTRAINT FK_OtpCodes_VerificationFlows
        FOREIGN KEY (FlowId) REFERENCES dbo.VerificationFlows(FlowId)
        ON DELETE CASCADE;
    PRINT '✓ FK_OtpCodes_VerificationFlows constraint added';
END

PRINT 'V006: Create Missing Tables - Completed Successfully';
GO