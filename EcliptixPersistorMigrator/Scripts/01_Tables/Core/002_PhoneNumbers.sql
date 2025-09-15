-- ============================================
-- Object: PhoneNumbers Table
-- Type: Core Table
-- Purpose: Stores phone numbers with regional information
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: None (Core table)
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.PhoneNumbers', 'U') IS NOT NULL
    DROP TABLE dbo.PhoneNumbers;
GO

-- Create PhoneNumbers table
-- Stores phone numbers with regional information
CREATE TABLE dbo.PhoneNumbers (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumber     NVARCHAR(18) NOT NULL,                                                       -- Phone number (up to 18 chars for international formats)
    Region          NVARCHAR(2),                                                                 -- Region code (ISO 3166-1 alpha-2)
    CreatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_PhoneNumbers_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_PhoneNumbers_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted       BIT NOT NULL CONSTRAINT DF_PhoneNumbers_IsDeleted DEFAULT 0,
    UniqueId        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_PhoneNumbers_UniqueId DEFAULT NEWID(),

    -- Unique constraints
    CONSTRAINT UQ_PhoneNumbers_UniqueId UNIQUE (UniqueId),
    CONSTRAINT UQ_PhoneNumbers_ActiveNumberRegion UNIQUE (PhoneNumber, Region, IsDeleted)       -- Unique active numbers in region
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_PhoneNumbers_PhoneNumber_Region
    ON dbo.PhoneNumbers (PhoneNumber, Region)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_PhoneNumbers_Region
    ON dbo.PhoneNumbers (Region)
    WHERE IsDeleted = 0 AND Region IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_PhoneNumbers_CreatedAt
    ON dbo.PhoneNumbers (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ PhoneNumbers table created successfully';
GO