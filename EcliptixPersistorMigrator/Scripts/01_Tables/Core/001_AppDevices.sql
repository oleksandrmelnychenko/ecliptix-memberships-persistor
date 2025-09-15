-- ============================================
-- Object: AppDevices Table
-- Type: Core Table
-- Purpose: Stores application device information and registration
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: None (Core table)
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.AppDevices', 'U') IS NOT NULL
    DROP TABLE dbo.AppDevices;
GO

-- Create AppDevices table
-- Stores information about application devices and instances
CREATE TABLE dbo.AppDevices (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    AppInstanceId   UNIQUEIDENTIFIER NOT NULL,                                                    -- Unique application instance identifier
    DeviceId        UNIQUEIDENTIFIER NOT NULL,                                                    -- Unique device identifier
    DeviceType      INT NOT NULL CONSTRAINT DF_AppDevices_DeviceType DEFAULT 1,                  -- Device type enumeration
    CreatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_AppDevices_CreatedAt DEFAULT GETUTCDATE(), -- Creation timestamp
    UpdatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_AppDevices_UpdatedAt DEFAULT GETUTCDATE(), -- Last update timestamp
    IsDeleted       BIT NOT NULL CONSTRAINT DF_AppDevices_IsDeleted DEFAULT 0,                    -- Soft delete flag
    UniqueId        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_AppDevices_UniqueId DEFAULT NEWID(),  -- Business unique identifier

    -- Unique constraints
    CONSTRAINT UQ_AppDevices_UniqueId UNIQUE (UniqueId),
    CONSTRAINT UQ_AppDevices_DeviceId UNIQUE (DeviceId)
);
GO

-- Create indexes for performance
CREATE NONCLUSTERED INDEX IX_AppDevices_AppInstanceId
    ON dbo.AppDevices (AppInstanceId);

CREATE NONCLUSTERED INDEX IX_AppDevices_DeviceType
    ON dbo.AppDevices (DeviceType)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_AppDevices_CreatedAt
    ON dbo.AppDevices (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ AppDevices table created successfully';
GO