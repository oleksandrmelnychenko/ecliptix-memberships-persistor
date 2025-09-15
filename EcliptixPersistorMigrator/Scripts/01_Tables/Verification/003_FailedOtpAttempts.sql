-- ============================================
-- Object: FailedOtpAttempts Table
-- Type: Verification Domain Table
-- Purpose: Tracks failed OTP verification attempts for security monitoring
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: OtpRecords, VerificationFlows
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.FailedOtpAttempts', 'U') IS NOT NULL
    DROP TABLE dbo.FailedOtpAttempts;
GO

-- Create FailedOtpAttempts table
-- Tracks failed OTP verification attempts for security and rate limiting
CREATE TABLE dbo.FailedOtpAttempts (
    Id                BIGINT IDENTITY(1,1) PRIMARY KEY,
    OtpUniqueId       UNIQUEIDENTIFIER NOT NULL,                                                 -- Reference to OtpRecords.UniqueId
    FlowUniqueId      UNIQUEIDENTIFIER NOT NULL,                                                 -- Reference to VerificationFlows.UniqueId
    AttemptTime       DATETIME2(7) NOT NULL CONSTRAINT DF_FailedOtpAttempts_AttemptTime DEFAULT GETUTCDATE(), -- When the attempt was made
    CreatedAt         DATETIME2(7) NOT NULL CONSTRAINT DF_FailedOtpAttempts_CreatedAt DEFAULT GETUTCDATE(),
    UpdatedAt         DATETIME2(7) NOT NULL CONSTRAINT DF_FailedOtpAttempts_UpdatedAt DEFAULT GETUTCDATE(),
    IsDeleted         BIT NOT NULL CONSTRAINT DF_FailedOtpAttempts_IsDeleted DEFAULT 0,

    -- Foreign key constraints
    CONSTRAINT FK_FailedOtpAttempts_OtpRecords
        FOREIGN KEY (OtpUniqueId)
        REFERENCES dbo.OtpRecords(UniqueId)
        ON DELETE CASCADE,

    CONSTRAINT FK_FailedOtpAttempts_VerificationFlows
        FOREIGN KEY (FlowUniqueId)
        REFERENCES dbo.VerificationFlows(UniqueId)
        ON DELETE NO ACTION
);
GO

-- Create indexes for performance and security monitoring
CREATE NONCLUSTERED INDEX IX_FailedOtpAttempts_OtpUniqueId
    ON dbo.FailedOtpAttempts (OtpUniqueId)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_FailedOtpAttempts_FlowUniqueId
    ON dbo.FailedOtpAttempts (FlowUniqueId)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_FailedOtpAttempts_AttemptTime
    ON dbo.FailedOtpAttempts (AttemptTime DESC)
    WHERE IsDeleted = 0;

-- Security monitoring indexes
CREATE NONCLUSTERED INDEX IX_FailedOtpAttempts_Recent
    ON dbo.FailedOtpAttempts (FlowUniqueId, AttemptTime)
    WHERE IsDeleted = 0;
GO

PRINT '✅ FailedOtpAttempts table created successfully';
GO