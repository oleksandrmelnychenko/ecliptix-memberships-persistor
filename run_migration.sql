-- Run this script directly against your database to set up the core system safely

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT 'Starting Safe System Setup...';

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

-- Add essential configuration values
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemConfiguration' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    -- Essential configuration values for the application
    MERGE dbo.SystemConfiguration AS target
    USING (VALUES
        ('Authentication.MaxFailedAttempts', '5', 'int', 'Maximum failed authentication attempts before lockout', 'Security'),
        ('Authentication.LockoutDurationMinutes', '5', 'int', 'Duration of account lockout in minutes', 'Security'),
        ('Authentication.ContextExpirationHours', '24', 'int', 'Default authentication context expiration in hours', 'Security'),
        ('OTP.MaxAttempts', '5', 'int', 'Maximum OTP attempts per flow', 'Security'),
        ('OTP.ExpirationMinutes', '5', 'int', 'OTP expiration time in minutes', 'Security'),
        ('RateLimit.MaxFlowsPerHour', '100', 'int', 'Maximum verification flows per phone number per hour', 'Security'),
        ('VerificationFlow.DefaultExpirationMinutes', '5', 'int', 'Default verification flow expiration in minutes', 'Security'),
        ('Monitoring.EnableMetrics', '1', 'bool', 'Enable performance metrics collection', 'Monitoring')
    ) AS source (ConfigKey, ConfigValue, DataType, Description, Category)
    ON target.ConfigKey = source.ConfigKey
    WHEN NOT MATCHED THEN
        INSERT (ConfigKey, ConfigValue, DataType, Description, Category)
        VALUES (source.ConfigKey, source.ConfigValue, source.DataType, source.Description, source.Category);

    PRINT '✓ Configuration values added/updated';
END

PRINT 'Safe System Setup Completed Successfully!';
PRINT 'Your EcliptixPersistorMigrator tool is now ready to use.';
GO