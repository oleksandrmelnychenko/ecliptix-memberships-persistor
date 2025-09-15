-- ============================================
-- Object: EventLog Table
-- Type: System Logging Table
-- Purpose: General event logging for application monitoring and debugging
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: None (Core logging table)
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing table if exists (for clean deployment)
IF OBJECT_ID('dbo.EventLog', 'U') IS NOT NULL
    DROP TABLE dbo.EventLog;
GO

-- Create EventLog table
-- General-purpose event logging for system monitoring and debugging
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EventLog')
BEGIN
    CREATE TABLE dbo.EventLog (
        Id          BIGINT IDENTITY(1,1) PRIMARY KEY,
        EventType   NVARCHAR(50) NOT NULL,                                                      -- Type of event being logged
        Message     NVARCHAR(MAX) NOT NULL,                                                     -- Event message or details
        CreatedAt   DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()                                 -- When the event occurred
    );
END
GO

-- Create indexes for performance and monitoring
CREATE NONCLUSTERED INDEX IX_EventLog_EventType_CreatedAt
    ON dbo.EventLog (EventType, CreatedAt DESC);

CREATE NONCLUSTERED INDEX IX_EventLog_CreatedAt
    ON dbo.EventLog (CreatedAt DESC);
GO

PRINT '✅ EventLog table created successfully';
GO