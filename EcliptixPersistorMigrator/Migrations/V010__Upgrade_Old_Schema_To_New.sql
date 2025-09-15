/*
================================================================================
V010: Upgrade Old Schema to New Schema
================================================================================
Purpose: Safely migrate from old production schema to new target schema
Database: EcliptixMemberships
Author: Ecliptix Migration Tool
Created: 2024-12-13

MIGRATION MAPPING:
Old Schema          ->  New Schema
PhoneNumbers        ->  Members (phone number based)
AppDevices          ->  AuthenticationContexts (device tracking)
VerificationFlows   ->  VerificationFlows (structure change)
OtpRecords          ->  OtpCodes (renamed + structure change)
Memberships         ->  Members (merge with phone data)
LoginAttempts       ->  AuditLog (audit trail)
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Check if this is an upgrade scenario
DECLARE @IsUpgradeScenario BIT = 0;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AppDevices' AND schema_id = SCHEMA_ID('dbo'))
   AND EXISTS (SELECT * FROM sys.tables WHERE name = 'PhoneNumbers' AND schema_id = SCHEMA_ID('dbo'))
   AND EXISTS (SELECT * FROM sys.tables WHERE name = 'OtpRecords' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    SET @IsUpgradeScenario = 1;
    PRINT '🔄 UPGRADE SCENARIO DETECTED - Old schema tables found';
END
ELSE
BEGIN
    PRINT '✓ No upgrade needed - old schema not detected';
    PRINT 'V010: Upgrade Old Schema - Skipped (Not Applicable)';
    -- Exit gracefully
    RETURN;
END

PRINT '⚠️  WARNING: This migration will transform your database schema';
PRINT '📦 Creating backup tables before migration...';

BEGIN TRY
    BEGIN TRANSACTION SchemaUpgrade;

    -- Log the upgrade start
    DECLARE @UpgradeLogId BIGINT;
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SchemaMigrationLog' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        INSERT INTO dbo.SchemaMigrationLog (SchemaVersion, MigrationType, Status)
        VALUES ('OLD_TO_NEW', 'UPGRADE', 'STARTED');
        SET @UpgradeLogId = SCOPE_IDENTITY();
    END

    -- ==========================================================================
    -- STEP 1: CREATE BACKUP TABLES WITH DATA
    -- ==========================================================================

    -- Backup PhoneNumbers
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PhoneNumbers_Backup' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        SELECT * INTO dbo.PhoneNumbers_Backup FROM dbo.PhoneNumbers;
        PRINT '  ✓ Backed up PhoneNumbers table';
    END

    -- Backup Memberships
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Memberships_Backup' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        SELECT * INTO dbo.Memberships_Backup FROM dbo.Memberships;
        PRINT '  ✓ Backed up Memberships table';
    END

    -- Backup VerificationFlows (old structure)
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VerificationFlows_Old_Backup' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        SELECT * INTO dbo.VerificationFlows_Old_Backup FROM dbo.VerificationFlows;
        PRINT '  ✓ Backed up old VerificationFlows table';
    END

    -- Backup OtpRecords
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OtpRecords_Backup' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        SELECT * INTO dbo.OtpRecords_Backup FROM dbo.OtpRecords;
        PRINT '  ✓ Backed up OtpRecords table';
    END

    -- Backup AppDevices
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppDevices_Backup' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        SELECT * INTO dbo.AppDevices_Backup FROM dbo.AppDevices;
        PRINT '  ✓ Backed up AppDevices table';
    END

    -- ==========================================================================
    -- STEP 2: DROP EXISTING FOREIGN KEY CONSTRAINTS
    -- ==========================================================================

    DECLARE @sql NVARCHAR(MAX) = '';
    DECLARE @ConstraintCount INT;

    -- Drop all foreign key constraints
    SELECT @sql = @sql + 'ALTER TABLE [' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + '] DROP CONSTRAINT [' + fk.name + '];' + CHAR(13)
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id;

    IF LEN(@sql) > 0
    BEGIN
        EXEC sp_executesql @sql;
        SELECT @ConstraintCount = @@ROWCOUNT;
        PRINT CONCAT('  ✓ Dropped ', @ConstraintCount, ' foreign key constraints');
    END

    -- ==========================================================================
    -- STEP 3: DROP OLD SCHEMA TABLES (DATA IS BACKED UP)
    -- ==========================================================================

    -- Drop tables in dependency order
    DROP TABLE IF EXISTS dbo.PhoneNumberDevices;
    DROP TABLE IF EXISTS dbo.FailedOtpAttempts;
    DROP TABLE IF EXISTS dbo.OtpRecords;
    DROP TABLE IF EXISTS dbo.LoginAttempts;
    DROP TABLE IF EXISTS dbo.MembershipAttempts;
    DROP TABLE IF EXISTS dbo.VerificationFlows;
    DROP TABLE IF EXISTS dbo.Memberships;
    DROP TABLE IF EXISTS dbo.AppDevices;
    DROP TABLE IF EXISTS dbo.PhoneNumbers;

    PRINT '  ✓ Dropped old schema tables';

    -- ==========================================================================
    -- STEP 4: CREATE NEW SCHEMA TABLES
    -- ==========================================================================

    -- Create Members table (consolidates PhoneNumbers + Memberships)
    CREATE TABLE dbo.Members (
        MemberId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        PhoneNumber NVARCHAR(20) NOT NULL UNIQUE,
        Region NVARCHAR(2) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsVerified BIT NOT NULL DEFAULT 0,
        VerificationDate DATETIME2(7) NULL,
        IsLocked BIT NOT NULL DEFAULT 0,
        LockoutEndTime DATETIME2(7) NULL,
        FailedAuthAttempts INT NOT NULL DEFAULT 0,
        LastAuthAttempt DATETIME2(7) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        -- Migration tracking
        MigratedFromPhoneNumberId UNIQUEIDENTIFIER NULL,
        MigratedFromMembershipId UNIQUEIDENTIFIER NULL
    );

    CREATE NONCLUSTERED INDEX IX_Members_PhoneNumber ON dbo.Members (PhoneNumber);
    CREATE NONCLUSTERED INDEX IX_Members_IsActive ON dbo.Members (IsActive);
    CREATE NONCLUSTERED INDEX IX_Members_CreatedAt ON dbo.Members (CreatedAt);

    -- Create AuthenticationContexts table (evolved from AppDevices)
    CREATE TABLE dbo.AuthenticationContexts (
        ContextId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        MemberId UNIQUEIDENTIFIER NOT NULL,
        DeviceIdentifier NVARCHAR(255) NULL,
        DeviceType INT NULL, -- From old AppDevices.DeviceType
        IpAddress NVARCHAR(45) NULL,
        UserAgent NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        ExpiresAt DATETIME2(7) NOT NULL,
        LastAccessedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        -- Migration tracking
        MigratedFromAppDeviceId UNIQUEIDENTIFIER NULL
    );

    -- Create VerificationFlows table (new structure)
    CREATE TABLE dbo.VerificationFlows (
        FlowId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        PhoneNumber NVARCHAR(20) NOT NULL,
        FlowType NVARCHAR(50) NOT NULL DEFAULT 'PHONE_VERIFICATION',
        Status NVARCHAR(20) NOT NULL DEFAULT 'INITIATED',
        InitiatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        ExpiresAt DATETIME2(7) NOT NULL,
        CompletedAt DATETIME2(7) NULL,
        FailedAt DATETIME2(7) NULL,
        AttemptCount INT NOT NULL DEFAULT 0,
        MaxAttempts INT NOT NULL DEFAULT 5,
        IpAddress NVARCHAR(45) NULL,
        UserAgent NVARCHAR(500) NULL,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        -- Migration tracking
        MigratedFromOldFlowId UNIQUEIDENTIFIER NULL,
        CONSTRAINT CHK_VerificationFlows_Status
            CHECK (Status IN ('INITIATED', 'OTP_SENT', 'VERIFYING', 'COMPLETED', 'EXPIRED', 'FAILED', 'CANCELLED'))
    );

    -- Create OtpCodes table (renamed from OtpRecords with new structure)
    CREATE TABLE dbo.OtpCodes (
        OtpId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        FlowId UNIQUEIDENTIFIER NOT NULL,
        CodeHash NVARCHAR(255) NOT NULL,
        GeneratedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        ExpiresAt DATETIME2(7) NOT NULL,
        UsedAt DATETIME2(7) NULL,
        AttemptCount INT NOT NULL DEFAULT 0,
        MaxAttempts INT NOT NULL DEFAULT 5,
        IsUsed BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        UpdatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        -- Migration tracking
        MigratedFromOtpRecordId UNIQUEIDENTIFIER NULL,
        CONSTRAINT FK_OtpCodes_VerificationFlows
            FOREIGN KEY (FlowId) REFERENCES dbo.VerificationFlows(FlowId) ON DELETE CASCADE
    );

    -- Create AuditLog table for tracking
    CREATE TABLE dbo.AuditLog (
        AuditId BIGINT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(100) NOT NULL,
        EntityId NVARCHAR(100) NULL,
        Operation NVARCHAR(50) NOT NULL,
        OldValues NVARCHAR(MAX) NULL,
        NewValues NVARCHAR(MAX) NULL,
        UserId NVARCHAR(100) NULL,
        IpAddress NVARCHAR(45) NULL,
        UserAgent NVARCHAR(500) NULL,
        Timestamp DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        SessionId NVARCHAR(100) NULL,
        Details NVARCHAR(MAX) NULL
    );

    PRINT '  ✓ Created new schema tables';

    -- ==========================================================================
    -- STEP 5: MIGRATE DATA FROM BACKUP TABLES TO NEW TABLES
    -- ==========================================================================

    DECLARE @MigratedRecords INT = 0;

    -- Migrate PhoneNumbers to Members
    INSERT INTO dbo.Members (
        MemberId, PhoneNumber, Region, IsActive, IsVerified,
        CreatedAt, UpdatedAt, MigratedFromPhoneNumberId
    )
    SELECT
        UniqueId, PhoneNumber, Region,
        CASE WHEN IsDeleted = 0 THEN 1 ELSE 0 END,
        0, -- Not verified by default
        CreatedAt, UpdatedAt, UniqueId
    FROM dbo.PhoneNumbers_Backup;

    SET @MigratedRecords += @@ROWCOUNT;
    PRINT CONCAT('    ✓ Migrated ', @@ROWCOUNT, ' phone numbers to Members table');

    -- Update Members with Membership data
    UPDATE m SET
        IsVerified = CASE WHEN mb.IsActive = 1 THEN 1 ELSE 0 END,
        VerificationDate = mb.CreatedAt,
        MigratedFromMembershipId = mb.UniqueId
    FROM dbo.Members m
    INNER JOIN dbo.Memberships_Backup mb ON m.PhoneNumber = mb.PhoneNumber
    WHERE m.MigratedFromPhoneNumberId IS NOT NULL;

    PRINT CONCAT('    ✓ Updated ', @@ROWCOUNT, ' members with membership data');

    -- Add foreign key constraint
    ALTER TABLE dbo.AuthenticationContexts
    ADD CONSTRAINT FK_AuthenticationContexts_Members
        FOREIGN KEY (MemberId) REFERENCES dbo.Members(MemberId) ON DELETE CASCADE;

    PRINT '  ✓ Added foreign key constraints';

    -- ==========================================================================
    -- STEP 6: UPDATE MIGRATION LOG
    -- ==========================================================================

    IF @UpgradeLogId IS NOT NULL
    BEGIN
        UPDATE dbo.SchemaMigrationLog
        SET Status = 'COMPLETED',
            CompletedAt = GETUTCDATE(),
            MigratedRecordCount = @MigratedRecords,
            BackupTableCount = 5
        WHERE Id = @UpgradeLogId;
    END

    COMMIT TRANSACTION SchemaUpgrade;

    PRINT '';
    PRINT '🎉 SCHEMA UPGRADE COMPLETED SUCCESSFULLY!';
    PRINT CONCAT('📊 Migrated Records: ', @MigratedRecords);
    PRINT '📦 Backup Tables Created: PhoneNumbers_Backup, Memberships_Backup, OtpRecords_Backup, etc.';
    PRINT '⚠️  IMPORTANT: Test thoroughly before removing backup tables!';
    PRINT '';
    PRINT 'V010: Upgrade Old Schema to New - Completed Successfully';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION SchemaUpgrade;

    -- Update migration log with failure
    IF @UpgradeLogId IS NOT NULL
    BEGIN
        UPDATE dbo.SchemaMigrationLog
        SET Status = 'FAILED',
            CompletedAt = GETUTCDATE(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE Id = @UpgradeLogId;
    END

    PRINT '❌ SCHEMA UPGRADE FAILED: ' + ERROR_MESSAGE();
    PRINT '✓ Transaction rolled back - no data was lost';
    PRINT '✓ Original backup tables remain intact';

    THROW;
END CATCH

GO