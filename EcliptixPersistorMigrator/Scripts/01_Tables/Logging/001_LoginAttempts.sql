-- ============================================
-- Object: LoginAttempts Table
-- Type: Security Logging Table
-- Purpose: Tracks login attempts for security monitoring and analytics
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: None (Logging table)
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.LoginAttempts', 'U') IS NOT NULL
    DROP TABLE dbo.LoginAttempts;
GO

-- Create LoginAttempts table
-- Tracks login attempts for security monitoring and user analytics
CREATE TABLE dbo.LoginAttempts (
    Id           BIGINT IDENTITY(1,1) PRIMARY KEY,
    Timestamp    DATETIME2(7) NOT NULL CONSTRAINT DF_LoginAttempts_Timestamp DEFAULT GETUTCDATE(),
    PhoneNumber  NVARCHAR(18) NOT NULL,                                                         -- Phone number used in login attempt
    Outcome      NVARCHAR(255) NOT NULL,                                                        -- Login attempt result description
    IsSuccess    BIT NOT NULL CONSTRAINT DF_LoginAttempts_IsSuccess DEFAULT 0,                -- Success flag
    CreatedAt    DATETIME2(7) NOT NULL CONSTRAINT DF_LoginAttempts_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt    DATETIME2(7) NOT NULL CONSTRAINT DF_LoginAttempts_UpdatedAt DEFAULT GETUTCDATE()
);
GO

-- Create indexes for security monitoring and analytics
CREATE NONCLUSTERED INDEX IX_LoginAttempts_PhoneNumber_Timestamp
    ON dbo.LoginAttempts (PhoneNumber, Timestamp);

CREATE NONCLUSTERED INDEX IX_LoginAttempts_Timestamp_Success
    ON dbo.LoginAttempts (Timestamp DESC, IsSuccess);

CREATE NONCLUSTERED INDEX IX_LoginAttempts_CreatedAt
    ON dbo.LoginAttempts (CreatedAt DESC);
GO

PRINT '✅ LoginAttempts table created successfully';
GO