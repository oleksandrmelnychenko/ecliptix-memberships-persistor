-- ============================================
-- Object: OtpRecords Table
-- Type: Verification Domain Table
-- Purpose: Stores OTP codes with secure hashing and lifecycle management
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: VerificationFlows, PhoneNumbers
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.OtpRecords', 'U') IS NOT NULL
    DROP TABLE dbo.OtpRecords;
GO

-- Create OtpRecords table
-- Stores one-time password records with secure hashing
CREATE TABLE dbo.OtpRecords (
    Id                BIGINT IDENTITY(1,1) PRIMARY KEY,
    FlowUniqueId      UNIQUEIDENTIFIER NOT NULL,                                                 -- Reference to VerificationFlows.UniqueId
    PhoneNumberId     BIGINT NOT NULL,                                                           -- Reference to PhoneNumbers.Id
    OtpHash           NVARCHAR(255) NOT NULL,                                                     -- Hashed OTP (never store plain text)
    OtpSalt           NVARCHAR(255) NOT NULL,                                                     -- Salt for OTP hashing
    ExpiresAt         DATETIME2(7) NOT NULL,                                                     -- OTP expiration timestamp
    Status            NVARCHAR(20) NOT NULL                                                      -- OTP status (ENUM-like)
        CONSTRAINT DF_OtpRecords_Status DEFAULT 'pending'
        CONSTRAINT CHK_OtpRecords_Status
        CHECK (Status IN ('pending', 'verified', 'expired', 'failed')),
    IsActive          BIT NOT NULL CONSTRAINT DF_OtpRecords_IsActive DEFAULT 1,                 -- Is this OTP currently active
    CreatedAt         DATETIME2(7) NOT NULL CONSTRAINT DF_OtpRecords_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt         DATETIME2(7) NOT NULL CONSTRAINT DF_OtpRecords_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted         BIT NOT NULL CONSTRAINT DF_OtpRecords_IsDeleted DEFAULT 0,
    UniqueId          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_OtpRecords_UniqueId DEFAULT NEWID(),

    -- Unique constraints
    CONSTRAINT UQ_OtpRecords_UniqueId UNIQUE (UniqueId),

    -- Foreign key constraints
    CONSTRAINT FK_OtpRecords_VerificationFlows
        FOREIGN KEY (FlowUniqueId)
        REFERENCES dbo.VerificationFlows(UniqueId)
        ON DELETE CASCADE,

    CONSTRAINT FK_OtpRecords_PhoneNumbers
        FOREIGN KEY (PhoneNumberId)
        REFERENCES dbo.PhoneNumbers(Id)
        ON DELETE NO ACTION
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_OtpRecords_FlowUniqueId_Status
    ON dbo.OtpRecords (FlowUniqueId, Status)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_OtpRecords_PhoneNumberId_IsActive
    ON dbo.OtpRecords (PhoneNumberId, IsActive)
    WHERE IsDeleted = 0 AND IsActive = 1;

CREATE NONCLUSTERED INDEX IX_OtpRecords_Status_ExpiresAt
    ON dbo.OtpRecords (Status, ExpiresAt)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_OtpRecords_ExpiresAt
    ON dbo.OtpRecords (ExpiresAt)
    WHERE IsDeleted = 0 AND Status = 'pending';

CREATE NONCLUSTERED INDEX IX_OtpRecords_CreatedAt
    ON dbo.OtpRecords (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ OtpRecords table created successfully';
GO