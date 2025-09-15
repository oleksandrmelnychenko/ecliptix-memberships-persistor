-- ============================================
-- Object: Memberships Table
-- Type: Membership Domain Table
-- Purpose: User memberships with secure key management and status tracking
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers, AppDevices, VerificationFlows
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.Memberships', 'U') IS NOT NULL
    DROP TABLE dbo.Memberships;
GO

-- Create Memberships table
-- Manages user memberships with secure key storage and status tracking
CREATE TABLE dbo.Memberships (
    Id                      BIGINT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumberId           UNIQUEIDENTIFIER NOT NULL,                                         -- Reference to PhoneNumbers.UniqueId
    AppDeviceId             UNIQUEIDENTIFIER NOT NULL,                                         -- Reference to AppDevices.UniqueId
    VerificationFlowId      UNIQUEIDENTIFIER NOT NULL,                                         -- Reference to VerificationFlows.UniqueId
    SecureKey               VARBINARY(MAX),                                                     -- Encrypted security key
    Status                  NVARCHAR(20) NOT NULL                                              -- Membership status (ENUM-like)
        CONSTRAINT DF_Memberships_Status DEFAULT 'inactive'
        CONSTRAINT CHK_Memberships_Status
        CHECK (Status IN ('active', 'inactive')),
    CreationStatus          NVARCHAR(20)                                                       -- Creation progress status (ENUM-like)
        CONSTRAINT CHK_Memberships_CreationStatus
        CHECK (CreationStatus IN ('otp_verified', 'secure_key_set', 'passphrase_set')),
    CreatedAt               DATETIME2(7) NOT NULL CONSTRAINT DF_Memberships_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt               DATETIME2(7) NOT NULL CONSTRAINT DF_Memberships_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted               BIT NOT NULL CONSTRAINT DF_Memberships_IsDeleted DEFAULT 0,
    UniqueId                UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Memberships_UniqueId DEFAULT NEWID(),

    -- Unique constraints
    CONSTRAINT UQ_Memberships_UniqueId UNIQUE (UniqueId),
    CONSTRAINT UQ_Memberships_ActiveMembership UNIQUE (PhoneNumberId, AppDeviceId, IsDeleted),

    -- Foreign key constraints
    CONSTRAINT FK_Memberships_PhoneNumbers
        FOREIGN KEY (PhoneNumberId)
        REFERENCES dbo.PhoneNumbers(UniqueId)
        ON DELETE NO ACTION,

    CONSTRAINT FK_Memberships_AppDevices
        FOREIGN KEY (AppDeviceId)
        REFERENCES dbo.AppDevices(UniqueId)
        ON DELETE NO ACTION,

    CONSTRAINT FK_Memberships_VerificationFlows
        FOREIGN KEY (VerificationFlowId)
        REFERENCES dbo.VerificationFlows(UniqueId)
        ON DELETE NO ACTION
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_Memberships_PhoneNumberId_Status
    ON dbo.Memberships (PhoneNumberId, Status)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_Memberships_AppDeviceId
    ON dbo.Memberships (AppDeviceId)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_Memberships_CreatedAt
    ON dbo.Memberships (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ Memberships table created successfully';
GO