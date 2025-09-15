/*
================================================================================
V002: Core Domain Tables
================================================================================
Purpose: Create all core business domain tables
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Drop foreign key constraints first
IF OBJECT_ID('FK_AuthenticationContexts_Members', 'F') IS NOT NULL
    ALTER TABLE dbo.AuthenticationContexts DROP CONSTRAINT FK_AuthenticationContexts_Members;
IF OBJECT_ID('FK_OtpCodes_VerificationFlows', 'F') IS NOT NULL
    ALTER TABLE dbo.OtpCodes DROP CONSTRAINT FK_OtpCodes_VerificationFlows;

-- Create Members table
IF OBJECT_ID('dbo.Members', 'U') IS NOT NULL
    DROP TABLE dbo.Members;

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

-- Create AuthenticationContexts table
IF OBJECT_ID('dbo.AuthenticationContexts', 'U') IS NOT NULL
    DROP TABLE dbo.AuthenticationContexts;

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
    UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT FK_AuthenticationContexts_Members
        FOREIGN KEY (MemberId) REFERENCES dbo.Members(MemberId)
        ON DELETE CASCADE
);

CREATE NONCLUSTERED INDEX IX_AuthenticationContexts_MemberId ON dbo.AuthenticationContexts (MemberId);
CREATE NONCLUSTERED INDEX IX_AuthenticationContexts_IsActive ON dbo.AuthenticationContexts (IsActive);
CREATE NONCLUSTERED INDEX IX_AuthenticationContexts_ExpiresAt ON dbo.AuthenticationContexts (ExpiresAt);

-- Create VerificationFlows table
IF OBJECT_ID('dbo.VerificationFlows', 'U') IS NOT NULL
    DROP TABLE dbo.VerificationFlows;

CREATE TABLE dbo.VerificationFlows (
    FlowId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber NVARCHAR(20) NOT NULL,
    FlowType NVARCHAR(50) NOT NULL DEFAULT 'PHONE_VERIFICATION',
    Status NVARCHAR(20) NOT NULL DEFAULT 'INITIATED',
    InitiatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    ExpiresAt DATETIME2(7) NOT NULL,
    CompletedAt DATETIME2(7) NULL,
    FailedAt DATETIME2(7) NULL,
    AttemptCount INT NOT NULL DEFAULT 0,
    MaxAttempts INT NOT NULL DEFAULT 5,
    IpAddress NVARCHAR(45) NULL,
    UserAgent NVARCHAR(500) NULL,
    CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT CHK_VerificationFlows_Status
        CHECK (Status IN ('INITIATED', 'OTP_SENT', 'VERIFYING', 'COMPLETED', 'EXPIRED', 'FAILED', 'CANCELLED')),
    CONSTRAINT CHK_VerificationFlows_FlowType
        CHECK (FlowType IN ('PHONE_VERIFICATION', 'PASSWORD_RESET', 'ACCOUNT_RECOVERY'))
);

CREATE NONCLUSTERED INDEX IX_VerificationFlows_PhoneNumber ON dbo.VerificationFlows (PhoneNumber);
CREATE NONCLUSTERED INDEX IX_VerificationFlows_Status ON dbo.VerificationFlows (Status);
CREATE NONCLUSTERED INDEX IX_VerificationFlows_ExpiresAt ON dbo.VerificationFlows (ExpiresAt);
CREATE NONCLUSTERED INDEX IX_VerificationFlows_CreatedAt ON dbo.VerificationFlows (CreatedAt);

-- Create OtpCodes table
IF OBJECT_ID('dbo.OtpCodes', 'U') IS NOT NULL
    DROP TABLE dbo.OtpCodes;

CREATE TABLE dbo.OtpCodes (
    OtpId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FlowId UNIQUEIDENTIFIER NOT NULL,
    CodeHash NVARCHAR(255) NOT NULL,
    GeneratedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    ExpiresAt DATETIME2(7) NOT NULL,
    UsedAt DATETIME2(7) NULL,
    AttemptCount INT NOT NULL DEFAULT 0,
    MaxAttempts INT NOT NULL DEFAULT 5,
    IsUsed BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    CONSTRAINT FK_OtpCodes_VerificationFlows
        FOREIGN KEY (FlowId) REFERENCES dbo.VerificationFlows(FlowId)
        ON DELETE CASCADE
);

CREATE NONCLUSTERED INDEX IX_OtpCodes_FlowId ON dbo.OtpCodes (FlowId);
CREATE NONCLUSTERED INDEX IX_OtpCodes_ExpiresAt ON dbo.OtpCodes (ExpiresAt);
CREATE NONCLUSTERED INDEX IX_OtpCodes_IsUsed ON dbo.OtpCodes (IsUsed);

-- Create AuditLog table
IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL
    DROP TABLE dbo.AuditLog;

CREATE TABLE dbo.AuditLog (
    AuditId BIGINT IDENTITY(1,1) PRIMARY KEY,
    EntityType NVARCHAR(100) NOT NULL,
    EntityId NVARCHAR(100) NULL,
    Operation NVARCHAR(50) NOT NULL,
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    UserId NVARCHAR(100) NULL,
    IpAddress NVARCHAR(45) NULL,
    UserAgent NVARCHAR(500) NULL,
    Timestamp DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    SessionId NVARCHAR(100) NULL,
    Details NVARCHAR(MAX) NULL
);

CREATE NONCLUSTERED INDEX IX_AuditLog_EntityType ON dbo.AuditLog (EntityType);
CREATE NONCLUSTERED INDEX IX_AuditLog_EntityId ON dbo.AuditLog (EntityId);
CREATE NONCLUSTERED INDEX IX_AuditLog_Operation ON dbo.AuditLog (Operation);
CREATE NONCLUSTERED INDEX IX_AuditLog_Timestamp ON dbo.AuditLog (Timestamp);
CREATE NONCLUSTERED INDEX IX_AuditLog_UserId ON dbo.AuditLog (UserId);

-- Create RateLimitTracking table
IF OBJECT_ID('dbo.RateLimitTracking', 'U') IS NOT NULL
    DROP TABLE dbo.RateLimitTracking;

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

PRINT 'V002: Core Domain Tables - Completed Successfully';
GO