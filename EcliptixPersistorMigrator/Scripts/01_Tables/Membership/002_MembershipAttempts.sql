-- ============================================
-- Object: MembershipAttempts Table
-- Type: Membership Domain Table
-- Purpose: Tracks membership creation attempts for monitoring and analytics
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.MembershipAttempts', 'U') IS NOT NULL
    DROP TABLE dbo.MembershipAttempts;
GO

-- Create MembershipAttempts table
-- Tracks attempts to create memberships for monitoring and analytics
CREATE TABLE dbo.MembershipAttempts (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumberId   UNIQUEIDENTIFIER NOT NULL,                                                 -- Reference to PhoneNumbers.UniqueId
    Timestamp       DATETIME2(7) NOT NULL CONSTRAINT DF_MembershipAttempts_Timestamp DEFAULT GETUTCDATE(),
    Outcome         NVARCHAR(255) NOT NULL,                                                     -- Attempt result description
    IsSuccess       BIT NOT NULL CONSTRAINT DF_MembershipAttempts_IsSuccess DEFAULT 0,        -- Success flag
    CreatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_MembershipAttempts_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2(7) NOT NULL CONSTRAINT DF_MembershipAttempts_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted       BIT NOT NULL CONSTRAINT DF_MembershipAttempts_IsDeleted DEFAULT 0,

    -- Foreign key constraints
    CONSTRAINT FK_MembershipAttempts_PhoneNumbers
        FOREIGN KEY (PhoneNumberId)
        REFERENCES dbo.PhoneNumbers(UniqueId)
        ON DELETE CASCADE
);
GO

-- Create indexes for performance and analytics
CREATE NONCLUSTERED INDEX IX_MembershipAttempts_PhoneNumberId_Timestamp
    ON dbo.MembershipAttempts (PhoneNumberId, Timestamp)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_MembershipAttempts_Timestamp_Success
    ON dbo.MembershipAttempts (Timestamp DESC, IsSuccess)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_MembershipAttempts_CreatedAt
    ON dbo.MembershipAttempts (CreatedAt DESC)
    WHERE IsDeleted = 0;
GO

PRINT '✅ MembershipAttempts table created successfully';
GO