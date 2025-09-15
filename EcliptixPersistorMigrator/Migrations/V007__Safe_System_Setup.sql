/*
================================================================================
V007: Safe System Setup
================================================================================
Purpose: Safely create all required system objects without conflicts
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Create SystemConfiguration table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemConfiguration' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.SystemConfiguration (
        ConfigKey NVARCHAR(100) PRIMARY KEY,
        ConfigValue NVARCHAR(500) NOT NULL,
        DataType NVARCHAR(20) NOT NULL DEFAULT 'string',
        Description NVARCHAR(1000) NOT NULL,
        Category NVARCHAR(50) NOT NULL DEFAULT 'General',
        IsEncrypted BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
        UpdatedBy NVARCHAR(100) DEFAULT SYSTEM_USER,
        CONSTRAINT CHK_SystemConfiguration_DataType
            CHECK (DataType IN ('string', 'int', 'bool', 'decimal', 'datetime'))
    );

    CREATE NONCLUSTERED INDEX IX_SystemConfiguration_Category
        ON dbo.SystemConfiguration (Category);
    CREATE NONCLUSTERED INDEX IX_SystemConfiguration_DataType
        ON dbo.SystemConfiguration (DataType);
    CREATE NONCLUSTERED INDEX IX_SystemConfiguration_UpdatedAt
        ON dbo.SystemConfiguration (UpdatedAt);

    PRINT '✓ SystemConfiguration table created';
END
ELSE
BEGIN
    PRINT '✓ SystemConfiguration table already exists';
END

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

-- Insert default configuration values only if they don't exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemConfiguration' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    -- Authentication settings
    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'Authentication.MaxFailedAttempts')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('Authentication.MaxFailedAttempts', '5', 'int', 'Maximum failed authentication attempts before lockout', 'Security');

    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'Authentication.LockoutDurationMinutes')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('Authentication.LockoutDurationMinutes', '5', 'int', 'Duration of account lockout in minutes', 'Security');

    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'Authentication.ContextExpirationHours')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('Authentication.ContextExpirationHours', '24', 'int', 'Default authentication context expiration in hours', 'Security');

    -- OTP settings
    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'OTP.MaxAttempts')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('OTP.MaxAttempts', '5', 'int', 'Maximum OTP attempts per flow', 'Security');

    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'OTP.ExpirationMinutes')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('OTP.ExpirationMinutes', '5', 'int', 'OTP expiration time in minutes', 'Security');

    -- Rate limiting
    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'RateLimit.MaxFlowsPerHour')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('RateLimit.MaxFlowsPerHour', '100', 'int', 'Maximum verification flows per phone number per hour', 'Security');

    -- Verification Flow
    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'VerificationFlow.DefaultExpirationMinutes')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('VerificationFlow.DefaultExpirationMinutes', '5', 'int', 'Default verification flow expiration in minutes', 'Security');

    -- Monitoring
    IF NOT EXISTS (SELECT * FROM dbo.SystemConfiguration WHERE ConfigKey = 'Monitoring.EnableMetrics')
        INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES ('Monitoring.EnableMetrics', '1', 'bool', 'Enable performance metrics collection', 'Monitoring');

    PRINT '✓ Default configuration values added';
END

PRINT 'V007: Safe System Setup - Completed Successfully';
GO