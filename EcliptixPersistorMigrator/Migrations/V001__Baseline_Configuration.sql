/*
================================================================================
V001: Baseline Configuration
================================================================================
Purpose: Create core configuration tables and functions
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Create SystemConfiguration table
IF OBJECT_ID('dbo.SystemConfiguration', 'U') IS NOT NULL
    DROP TABLE dbo.SystemConfiguration;

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

-- Create GetConfigValue function
IF OBJECT_ID('dbo.GetConfigValue', 'FN') IS NOT NULL
    DROP FUNCTION dbo.GetConfigValue;
GO

CREATE FUNCTION dbo.GetConfigValue(@ConfigKey NVARCHAR(100))
RETURNS NVARCHAR(500)
AS
BEGIN
    DECLARE @ConfigValue NVARCHAR(500);

    SELECT @ConfigValue = ConfigValue
    FROM dbo.SystemConfiguration
    WHERE ConfigKey = @ConfigKey;

    RETURN ISNULL(@ConfigValue, '');
END;
GO

-- Create SetConfigValue procedure
IF OBJECT_ID('dbo.SetConfigValue', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SetConfigValue;
GO

CREATE PROCEDURE dbo.SetConfigValue
    @ConfigKey NVARCHAR(100),
    @ConfigValue NVARCHAR(500),
    @UpdatedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ConfigKey IS NULL OR LEN(TRIM(@ConfigKey)) = 0
    BEGIN
        RAISERROR('Configuration key cannot be null or empty', 16, 1);
        RETURN;
    END

    IF @ConfigValue IS NULL
    BEGIN
        RAISERROR('Configuration value cannot be null', 16, 1);
        RETURN;
    END

    UPDATE dbo.SystemConfiguration
    SET ConfigValue = @ConfigValue,
        UpdatedAt = GETUTCDATE(),
        UpdatedBy = ISNULL(@UpdatedBy, SYSTEM_USER)
    WHERE ConfigKey = @ConfigKey;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('Configuration key %s not found', 16, 1, @ConfigKey);
        RETURN;
    END

    SELECT 1 AS Success, 'Configuration updated successfully' AS Message;
END;
GO

PRINT 'V001: Baseline Configuration - Completed Successfully';
GO