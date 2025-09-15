-- ============================================
-- Object: PhoneNumberDevices Table
-- Type: Relationship Table
-- Purpose: Many-to-many relationship between phone numbers and devices
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: AppDevices, PhoneNumbers
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.PhoneNumberDevices', 'U') IS NOT NULL
    DROP TABLE dbo.PhoneNumberDevices;
GO

-- Create PhoneNumberDevices relationship table
-- Links phone numbers with devices (many-to-many)
CREATE TABLE dbo.PhoneNumberDevices (
    PhoneNumberId   UNIQUEIDENTIFIER NOT NULL,                                                   -- Reference to PhoneNumbers.UniqueId
    AppDeviceId     UNIQUEIDENTIFIER NOT NULL,                                                   -- Reference to AppDevices.UniqueId
    IsPrimary       BIT NOT NULL CONSTRAINT DF_PhoneNumberDevices_IsPrimary DEFAULT 0,          -- Is this the primary device for the phone
    CreatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_PhoneNumberDevices_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_PhoneNumberDevices_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted       BIT NOT NULL CONSTRAINT DF_PhoneNumberDevices_IsDeleted DEFAULT 0,

    -- Composite primary key
    CONSTRAINT PK_PhoneNumberDevices PRIMARY KEY (PhoneNumberId, AppDeviceId),

    -- Foreign key constraints
    CONSTRAINT FK_PhoneNumberDevices_PhoneNumbers
        FOREIGN KEY (PhoneNumberId)
        REFERENCES dbo.PhoneNumbers(UniqueId)
        ON DELETE CASCADE,

    CONSTRAINT FK_PhoneNumberDevices_AppDevices
        FOREIGN KEY (AppDeviceId)
        REFERENCES dbo.AppDevices(UniqueId)
        ON DELETE CASCADE
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_PhoneNumberDevices_AppDeviceId
    ON dbo.PhoneNumberDevices (AppDeviceId)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_PhoneNumberDevices_IsPrimary
    ON dbo.PhoneNumberDevices (PhoneNumberId, IsPrimary)
    WHERE IsDeleted = 0 AND IsPrimary = 1;

CREATE NONCLUSTERED INDEX IX_PhoneNumberDevices_CreatedAt
    ON dbo.PhoneNumberDevices (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ PhoneNumberDevices relationship table created successfully';
GO