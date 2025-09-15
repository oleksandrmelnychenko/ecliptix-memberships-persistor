-- ============================================
-- Object: VerificationFlows Table
-- Type: Verification Domain Table
-- Purpose: Manages phone verification workflows and their lifecycle
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers, AppDevices
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.VerificationFlows', 'U') IS NOT NULL
    DROP TABLE dbo.VerificationFlows;
GO

-- Create VerificationFlows table
-- Manages phone verification processes and their states
CREATE TABLE dbo.VerificationFlows (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumberId   BIGINT NOT NULL,                                                             -- Reference to PhoneNumbers.Id
    AppDeviceId     UNIQUEIDENTIFIER NOT NULL,                                                   -- Reference to AppDevices.UniqueId
    Status          NVARCHAR(20) NOT NULL                                                        -- Flow status (ENUM-like)
        CONSTRAINT DF_VerificationFlows_Status DEFAULT 'pending'
        CONSTRAINT CHK_VerificationFlows_Status
        CHECK (Status IN ('pending', 'verified', 'expired', 'failed')),
    Purpose         NVARCHAR(30) NOT NULL                                                        -- Flow purpose (ENUM-like)
        CONSTRAINT DF_VerificationFlows_Purpose DEFAULT 'unspecified'
        CONSTRAINT CHK_VerificationFlows_Purpose
        CHECK (Purpose IN ('unspecified', 'registration', 'login', 'password_recovery', 'update_phone')),
    ExpiresAt       DATETIME2(7) NOT NULL,                                                       -- Expiration timestamp
    OtpCount        SMALLINT NOT NULL CONSTRAINT DF_VerificationFlows_OtpCount DEFAULT 0,       -- Number of OTPs generated
    ConnectionId    BIGINT,                                                                      -- Optional connection identifier
    CreatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_VerificationFlows_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_VerificationFlows_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted       BIT NOT NULL CONSTRAINT DF_VerificationFlows_IsDeleted DEFAULT 0,
    UniqueId        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_VerificationFlows_UniqueId DEFAULT NEWID(),

    -- Unique constraints
    CONSTRAINT UQ_VerificationFlows_UniqueId UNIQUE (UniqueId),

    -- Foreign key constraints
    CONSTRAINT FK_VerificationFlows_PhoneNumbers
        FOREIGN KEY (PhoneNumberId)
        REFERENCES dbo.PhoneNumbers(Id)
        ON DELETE CASCADE,

    CONSTRAINT FK_VerificationFlows_AppDevices
        FOREIGN KEY (AppDeviceId)
        REFERENCES dbo.AppDevices(UniqueId)
        ON DELETE CASCADE,

    -- Business rules
    CONSTRAINT CHK_VerificationFlows_OtpCount CHECK (OtpCount >= 0)
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_VerificationFlows_PhoneNumberId_Status
    ON dbo.VerificationFlows (PhoneNumberId, Status)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_VerificationFlows_AppDeviceId_Purpose
    ON dbo.VerificationFlows (AppDeviceId, Purpose)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_VerificationFlows_Status_ExpiresAt
    ON dbo.VerificationFlows (Status, ExpiresAt)
    WHERE IsDeleted = 0;

-- Unique constraint for active flows
CREATE UNIQUE INDEX UQ_VerificationFlows_Pending
    ON dbo.VerificationFlows (AppDeviceId, PhoneNumberId, Purpose)
    WHERE (Status = 'pending' AND IsDeleted = 0);

CREATE NONCLUSTERED INDEX IX_VerificationFlows_CreatedAt
    ON dbo.VerificationFlows (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ VerificationFlows table created successfully';
GO