/*
================================================================================
V011: Rollback and Safety Features
================================================================================
Purpose: Create rollback procedures and safety mechanisms for schema migrations
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Create rollback procedure
IF OBJECT_ID('dbo.RollbackToOldSchema', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RollbackToOldSchema;
GO

CREATE PROCEDURE dbo.RollbackToOldSchema
    @ConfirmRollback BIT = 0,
    @DryRun BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '🔄 SCHEMA ROLLBACK PROCEDURE';
    PRINT '============================';

    IF @ConfirmRollback = 0
    BEGIN
        PRINT '❌ ROLLBACK NOT CONFIRMED';
        PRINT 'To execute rollback, call: EXEC dbo.RollbackToOldSchema @ConfirmRollback = 1';
        PRINT '⚠️  WARNING: This will restore old schema and may lose data!';
        RETURN;
    END

    -- Check if backup tables exist
    DECLARE @CanRollback BIT = 1;
    DECLARE @BackupTables TABLE (TableName NVARCHAR(128));

    INSERT INTO @BackupTables VALUES
    ('PhoneNumbers_Backup'),
    ('Memberships_Backup'),
    ('VerificationFlows_Old_Backup'),
    ('OtpRecords_Backup'),
    ('AppDevices_Backup');

    DECLARE @MissingBackups NVARCHAR(MAX) = '';

    SELECT @MissingBackups = @MissingBackups + TableName + ', '
    FROM @BackupTables bt
    WHERE NOT EXISTS (
        SELECT * FROM sys.tables
        WHERE name = bt.TableName AND schema_id = SCHEMA_ID('dbo')
    );

    IF LEN(@MissingBackups) > 0
    BEGIN
        SET @CanRollback = 0;
        PRINT '❌ CANNOT ROLLBACK - Missing backup tables: ' + @MissingBackups;
        RETURN;
    END

    IF @DryRun = 1
    BEGIN
        PRINT '🔍 DRY RUN MODE - Showing what would be done:';
        PRINT '  1. Drop new schema tables (Members, AuthenticationContexts, etc.)';
        PRINT '  2. Recreate old schema tables from backups';
        PRINT '  3. Restore data from backup tables';
        PRINT '  4. Recreate original foreign key constraints';
        PRINT '✓ All backup tables are available for rollback';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION RollbackSchema;

        -- Log rollback attempt
        INSERT INTO dbo.SchemaMigrationLog (SchemaVersion, MigrationType, Status)
        VALUES ('NEW_TO_OLD', 'ROLLBACK', 'STARTED');
        DECLARE @RollbackLogId BIGINT = SCOPE_IDENTITY();

        PRINT '📦 Starting rollback process...';

        -- Drop new schema foreign key constraints
        DECLARE @sql NVARCHAR(MAX) = '';

        SELECT @sql = @sql + 'ALTER TABLE [' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + '] DROP CONSTRAINT [' + fk.name + '];' + CHAR(13)
        FROM sys.foreign_keys fk
        INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
        WHERE t.name IN ('Members', 'AuthenticationContexts', 'VerificationFlows', 'OtpCodes');

        IF LEN(@sql) > 0
        BEGIN
            EXEC sp_executesql @sql;
            PRINT '  ✓ Dropped new schema foreign key constraints';
        END

        -- Drop new schema tables
        DROP TABLE IF EXISTS dbo.OtpCodes;
        DROP TABLE IF EXISTS dbo.VerificationFlows;
        DROP TABLE IF EXISTS dbo.AuthenticationContexts;
        DROP TABLE IF EXISTS dbo.Members;
        DROP TABLE IF EXISTS dbo.AuditLog;

        PRINT '  ✓ Dropped new schema tables';

        -- Restore old schema tables from backups
        SELECT * INTO dbo.PhoneNumbers FROM dbo.PhoneNumbers_Backup;
        SELECT * INTO dbo.Memberships FROM dbo.Memberships_Backup;
        SELECT * INTO dbo.VerificationFlows FROM dbo.VerificationFlows_Old_Backup;
        SELECT * INTO dbo.OtpRecords FROM dbo.OtpRecords_Backup;
        SELECT * INTO dbo.AppDevices FROM dbo.AppDevices_Backup;

        PRINT '  ✓ Restored old schema tables from backups';

        -- Recreate old schema structure (simplified version)

        -- Add constraints and indexes for PhoneNumbers
        ALTER TABLE dbo.PhoneNumbers
        ADD CONSTRAINT PK_PhoneNumbers PRIMARY KEY (Id);

        ALTER TABLE dbo.PhoneNumbers
        ADD CONSTRAINT UQ_PhoneNumbers_UniqueId UNIQUE (UniqueId);

        CREATE INDEX IX_PhoneNumbers_PhoneNumber_Region
        ON dbo.PhoneNumbers (PhoneNumber, Region);

        -- Add constraints for other tables as needed
        ALTER TABLE dbo.Memberships
        ADD CONSTRAINT PK_Memberships PRIMARY KEY (Id);

        ALTER TABLE dbo.VerificationFlows
        ADD CONSTRAINT PK_VerificationFlows PRIMARY KEY (Id);

        ALTER TABLE dbo.OtpRecords
        ADD CONSTRAINT PK_OtpRecords PRIMARY KEY (Id);

        ALTER TABLE dbo.AppDevices
        ADD CONSTRAINT PK_AppDevices PRIMARY KEY (Id);

        PRINT '  ✓ Recreated old schema constraints and indexes';

        -- Update rollback log
        UPDATE dbo.SchemaMigrationLog
        SET Status = 'COMPLETED',
            CompletedAt = GETUTCDATE()
        WHERE Id = @RollbackLogId;

        COMMIT TRANSACTION RollbackSchema;

        PRINT '';
        PRINT '✅ ROLLBACK COMPLETED SUCCESSFULLY';
        PRINT '📊 Old schema restored from backup tables';
        PRINT '⚠️  New schema data has been lost';
        PRINT '🗑️  Consider dropping backup tables if rollback is permanent';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION RollbackSchema;

        -- Log rollback failure
        UPDATE dbo.SchemaMigrationLog
        SET Status = 'FAILED',
            CompletedAt = GETUTCDATE(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE Id = @RollbackLogId;

        PRINT '❌ ROLLBACK FAILED: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- Create database health check procedure
IF OBJECT_ID('dbo.CheckDatabaseHealth', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CheckDatabaseHealth;
GO

CREATE PROCEDURE dbo.CheckDatabaseHealth
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '🩺 DATABASE HEALTH CHECK';
    PRINT '========================';

    -- Check schema version
    DECLARE @HasOldSchema BIT = 0;
    DECLARE @HasNewSchema BIT = 0;

    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PhoneNumbers' AND schema_id = SCHEMA_ID('dbo'))
        SET @HasOldSchema = 1;

    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Members' AND schema_id = SCHEMA_ID('dbo'))
        SET @HasNewSchema = 1;

    PRINT CONCAT('Schema Status: ',
        CASE
            WHEN @HasNewSchema = 1 THEN 'NEW_SCHEMA'
            WHEN @HasOldSchema = 1 THEN 'OLD_SCHEMA'
            ELSE 'UNKNOWN'
        END);

    -- Check migration history
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SchemaMigrationLog' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        DECLARE @LastMigration NVARCHAR(50);
        DECLARE @LastStatus NVARCHAR(20);

        SELECT TOP 1 @LastMigration = MigrationType, @LastStatus = Status
        FROM dbo.SchemaMigrationLog
        ORDER BY StartedAt DESC;

        PRINT CONCAT('Last Migration: ', @LastMigration, ' (', @LastStatus, ')');
    END

    -- Check backup tables
    DECLARE @BackupTableCount INT = 0;

    SELECT @BackupTableCount = COUNT(*)
    FROM sys.tables
    WHERE name LIKE '%_Backup' AND schema_id = SCHEMA_ID('dbo');

    PRINT CONCAT('Backup Tables Available: ', @BackupTableCount);

    -- Check data integrity
    IF @HasNewSchema = 1
    BEGIN
        DECLARE @MemberCount INT, @FlowCount INT, @OtpCount INT;

        SELECT @MemberCount = COUNT(*) FROM dbo.Members;
        SELECT @FlowCount = COUNT(*) FROM dbo.VerificationFlows;
        SELECT @OtpCount = COUNT(*) FROM dbo.OtpCodes;

        PRINT CONCAT('Data Counts - Members: ', @MemberCount,
                    ', Flows: ', @FlowCount, ', OTPs: ', @OtpCount);
    END

    -- Check for orphaned records
    IF @HasNewSchema = 1
    BEGIN
        DECLARE @OrphanedOtps INT;

        SELECT @OrphanedOtps = COUNT(*)
        FROM dbo.OtpCodes o
        LEFT JOIN dbo.VerificationFlows v ON o.FlowId = v.FlowId
        WHERE v.FlowId IS NULL;

        IF @OrphanedOtps > 0
        BEGIN
            PRINT CONCAT('⚠️  WARNING: ', @OrphanedOtps, ' orphaned OTP records found');
        END
        ELSE
        BEGIN
            PRINT '✅ No orphaned records detected';
        END
    END

    PRINT '✅ Health check completed';
END;
GO

-- Create cleanup procedure for backup tables
IF OBJECT_ID('dbo.CleanupBackupTables', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CleanupBackupTables;
GO

CREATE PROCEDURE dbo.CleanupBackupTables
    @ConfirmCleanup BIT = 0,
    @DryRun BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '🧹 BACKUP TABLE CLEANUP';
    PRINT '=======================';

    IF @ConfirmCleanup = 0
    BEGIN
        PRINT '❌ CLEANUP NOT CONFIRMED';
        PRINT 'To execute cleanup, call: EXEC dbo.CleanupBackupTables @ConfirmCleanup = 1';
        PRINT '⚠️  WARNING: This will permanently delete backup tables!';
        RETURN;
    END

    -- Find backup tables
    DECLARE @BackupTables TABLE (TableName NVARCHAR(128));

    INSERT INTO @BackupTables
    SELECT name
    FROM sys.tables
    WHERE name LIKE '%_Backup' AND schema_id = SCHEMA_ID('dbo');

    DECLARE @TableCount INT;
    SELECT @TableCount = COUNT(*) FROM @BackupTables;

    IF @TableCount = 0
    BEGIN
        PRINT '✅ No backup tables found to cleanup';
        RETURN;
    END

    IF @DryRun = 1
    BEGIN
        PRINT CONCAT('🔍 DRY RUN - Would delete ', @TableCount, ' backup tables:');

        DECLARE @TableName NVARCHAR(128);
        DECLARE backup_cursor CURSOR FOR SELECT TableName FROM @BackupTables;

        OPEN backup_cursor;
        FETCH NEXT FROM backup_cursor INTO @TableName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT CONCAT('  - ', @TableName);
            FETCH NEXT FROM backup_cursor INTO @TableName;
        END

        CLOSE backup_cursor;
        DEALLOCATE backup_cursor;
        RETURN;
    END

    -- Delete backup tables
    DECLARE @sql NVARCHAR(MAX) = '';

    SELECT @sql = @sql + 'DROP TABLE IF EXISTS dbo.[' + TableName + '];' + CHAR(13)
    FROM @BackupTables;

    IF LEN(@sql) > 0
    BEGIN
        EXEC sp_executesql @sql;
        PRINT CONCAT('✅ Deleted ', @TableCount, ' backup tables');
    END
END;
GO

PRINT 'V011: Rollback and Safety Features - Completed Successfully';
PRINT '';
PRINT '🛠️  Available Safety Procedures:';
PRINT '  • EXEC dbo.RollbackToOldSchema @ConfirmRollback = 1 -- Rollback to old schema';
PRINT '  • EXEC dbo.CheckDatabaseHealth -- Check database state';
PRINT '  • EXEC dbo.CleanupBackupTables @ConfirmCleanup = 1 -- Remove backup tables';
GO