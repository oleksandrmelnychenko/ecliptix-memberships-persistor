/*
================================================================================
V009: Core Functions and Procedures
================================================================================
Purpose: Create essential functions and procedures for the new schema
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Create GetConfigValue function if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.GetConfigValue') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    EXEC('
    CREATE FUNCTION dbo.GetConfigValue(@ConfigKey NVARCHAR(100))
    RETURNS NVARCHAR(500)
    AS
    BEGIN
        DECLARE @ConfigValue NVARCHAR(500);

        SELECT @ConfigValue = ConfigValue
        FROM dbo.SystemConfiguration
        WHERE ConfigKey = @ConfigKey;

        RETURN ISNULL(@ConfigValue, '''');
    END
    ');
    PRINT '✓ GetConfigValue function created';
END
ELSE
BEGIN
    PRINT '✓ GetConfigValue function already exists';
END

-- Create SetConfigValue procedure if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.SetConfigValue') AND type in (N'P', N'PC'))
BEGIN
    EXEC('
    CREATE PROCEDURE dbo.SetConfigValue
        @ConfigKey NVARCHAR(100),
        @ConfigValue NVARCHAR(500),
        @UpdatedBy NVARCHAR(100) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        IF @ConfigKey IS NULL OR LEN(TRIM(@ConfigKey)) = 0
        BEGIN
            RAISERROR(''Configuration key cannot be null or empty'', 16, 1);
            RETURN;
        END

        IF @ConfigValue IS NULL
        BEGIN
            RAISERROR(''Configuration value cannot be null'', 16, 1);
            RETURN;
        END

        UPDATE dbo.SystemConfiguration
        SET ConfigValue = @ConfigValue,
            UpdatedAt = GETUTCDATE(),
            UpdatedBy = ISNULL(@UpdatedBy, SYSTEM_USER)
        WHERE ConfigKey = @ConfigKey;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(''Configuration key %s not found'', 16, 1, @ConfigKey);
            RETURN;
        END

        SELECT 1 AS Success, ''Configuration updated successfully'' AS Message;
    END
    ');
    PRINT '✓ SetConfigValue procedure created';
END
ELSE
BEGIN
    PRINT '✓ SetConfigValue procedure already exists';
END

-- Add essential configuration values
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemConfiguration' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    -- Authentication settings
    MERGE dbo.SystemConfiguration AS target
    USING (VALUES
        ('Authentication.MaxFailedAttempts', '5', 'int', 'Maximum failed authentication attempts before lockout', 'Security'),
        ('Authentication.LockoutDurationMinutes', '5', 'int', 'Duration of account lockout in minutes', 'Security'),
        ('Authentication.ContextExpirationHours', '24', 'int', 'Default authentication context expiration in hours', 'Security'),
        ('Authentication.MaxSessionsPerUser', '5', 'int', 'Maximum concurrent sessions per user', 'Security'),
        ('OTP.MaxAttempts', '5', 'int', 'Maximum OTP attempts per flow', 'Security'),
        ('OTP.ExpirationMinutes', '5', 'int', 'OTP expiration time in minutes', 'Security'),
        ('OTP.ResendCooldownSeconds', '30', 'int', 'Minimum seconds between OTP resend requests', 'Security'),
        ('RateLimit.MaxFlowsPerHour', '100', 'int', 'Maximum verification flows per phone number per hour', 'Security'),
        ('RateLimit.WindowHours', '1', 'int', 'Rate limiting window in hours', 'Security'),
        ('VerificationFlow.DefaultExpirationMinutes', '5', 'int', 'Default verification flow expiration in minutes', 'Security'),
        ('Monitoring.EnableMetrics', '1', 'bool', 'Enable performance metrics collection', 'Monitoring'),
        ('Database.CleanupBatchSize', '1000', 'int', 'Batch size for cleanup operations', 'Performance'),
        ('Database.RetentionDays', '90', 'int', 'Data retention period in days', 'Performance')
    ) AS source (ConfigKey, ConfigValue, DataType, Description, Category)
    ON target.ConfigKey = source.ConfigKey
    WHEN NOT MATCHED THEN
        INSERT (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES (source.ConfigKey, source.ConfigValue, source.DataType, source.Description, source.Category)
    WHEN MATCHED THEN
        UPDATE SET
            Description = source.Description,
            Category = source.Category,
            UpdatedAt = GETUTCDATE();

    PRINT '✓ Essential configuration values added/updated';
END

PRINT 'V009: Core Functions and Procedures - Completed Successfully';
GO