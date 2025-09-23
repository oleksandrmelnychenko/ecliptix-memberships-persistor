-- ============================================================================
-- SP_LogEvent - System event logging utility
-- ============================================================================
-- Purpose: Centralized logging for all system events and operations
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_LogEvent
    @EventType NVARCHAR(50),
    @Severity NVARCHAR(20) = 'info',
    @Message NVARCHAR(200),
    @Details NVARCHAR(4000) = NULL,
    @EntityType NVARCHAR(100) = NULL,
    @EntityId BIGINT = NULL,
    @UserId UNIQUEIDENTIFIER = NULL,
    @SessionId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure EventLogs table exists before inserting
    IF OBJECT_ID(N'dbo.EventLogs', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.EventLogs (
            Id BIGINT IDENTITY(1,1) PRIMARY KEY,
            UniqueId UNIQUEIDENTIFIER NOT NULL,
            EventType NVARCHAR(50) NOT NULL,
            Severity NVARCHAR(20) NOT NULL,
            Message NVARCHAR(200) NOT NULL,
            Details NVARCHAR(4000) NULL,
            EntityType NVARCHAR(100) NULL,
            EntityId BIGINT NULL,
            UserId UNIQUEIDENTIFIER NULL,
            SessionId NVARCHAR(100) NULL,
            OccurredAt DATETIME2 NOT NULL,
            CreatedAt DATETIME2 NOT NULL,
            UpdatedAt DATETIME2 NOT NULL,
            IsDeleted BIT NOT NULL DEFAULT 0
        );
    END

    BEGIN TRY
        -- Validate severity
        IF @Severity NOT IN ('trace', 'debug', 'info', 'warning', 'error', 'critical')
        BEGIN
            SET @Severity = 'info';
        END

        -- Insert event log
        INSERT INTO dbo.EventLogs (
            EventType, Severity, Message, Details, EntityType, EntityId,
            UserId, SessionId, OccurredAt,
            CreatedAt, UpdatedAt, IsDeleted, UniqueId
        )
        VALUES (
            @EventType, @Severity, @Message, @Details, @EntityType, @EntityId,
            @UserId, @SessionId, GETUTCDATE(),
            GETUTCDATE(), GETUTCDATE(), 0, NEWID()
        );

        -- For critical errors, you might want to send alerts
        IF @Severity = 'critical'
        BEGIN
            -- Could trigger alerts, notifications, etc.
            -- For now, just ensure it's logged
            PRINT 'CRITICAL EVENT LOGGED: ' + @Message;
        END

    END TRY
    BEGIN CATCH
        -- Even logging can fail, but we don't want to break the calling procedure
        -- Log to SQL Server error log as fallback
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Failed to log event: ' + ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 10, 1) WITH LOG;
    END CATCH
END
GO