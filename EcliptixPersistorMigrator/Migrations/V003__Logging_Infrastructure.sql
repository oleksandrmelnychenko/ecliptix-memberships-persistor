/*
================================================================================
V003: Logging Infrastructure
================================================================================
Purpose: Comprehensive audit logging, error tracking, and performance monitoring
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ERROR LOG TABLE
IF OBJECT_ID('dbo.ErrorLog','U') IS NOT NULL DROP TABLE dbo.ErrorLog;

CREATE TABLE dbo.ErrorLog (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProcedureName NVARCHAR(100) NOT NULL,
    ErrorNumber INT NOT NULL,
    ErrorMessage NVARCHAR(MAX) NOT NULL,
    ErrorSeverity INT NOT NULL,
    ErrorState INT NOT NULL,
    ErrorLine INT,
    Parameters NVARCHAR(MAX),
    StackTrace NVARCHAR(MAX),
    UserId UNIQUEIDENTIFIER,
    SessionId NVARCHAR(100),
    IpAddress NVARCHAR(45),
    UserAgent NVARCHAR(500),
    CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
);

CREATE NONCLUSTERED INDEX IX_ErrorLog_CreatedAt ON dbo.ErrorLog (CreatedAt);
CREATE NONCLUSTERED INDEX IX_ErrorLog_ProcedureName_CreatedAt ON dbo.ErrorLog (ProcedureName, CreatedAt);
CREATE NONCLUSTERED INDEX IX_ErrorLog_ErrorNumber ON dbo.ErrorLog (ErrorNumber);
CREATE NONCLUSTERED INDEX IX_ErrorLog_UserId_CreatedAt ON dbo.ErrorLog (UserId, CreatedAt) WHERE UserId IS NOT NULL;

-- PERFORMANCE METRICS TABLE
IF OBJECT_ID('dbo.PerformanceMetrics','U') IS NOT NULL DROP TABLE dbo.PerformanceMetrics;

CREATE TABLE dbo.PerformanceMetrics (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    OperationName NVARCHAR(100) NOT NULL,
    OperationType NVARCHAR(50) NOT NULL,
    ExecutionTimeMs INT NOT NULL,
    CpuTimeMs INT,
    MemoryUsageMB DECIMAL(10,2),
    RowsAffected INT,
    DatabaseName NVARCHAR(100),
    UserId UNIQUEIDENTIFIER,
    SessionId NVARCHAR(100),
    Parameters NVARCHAR(MAX),
    Success BIT NOT NULL DEFAULT 1,
    ErrorMessage NVARCHAR(500),
    CreatedAt DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
);

CREATE NONCLUSTERED INDEX IX_PerformanceMetrics_CreatedAt ON dbo.PerformanceMetrics (CreatedAt);
CREATE NONCLUSTERED INDEX IX_PerformanceMetrics_OperationName_CreatedAt ON dbo.PerformanceMetrics (OperationName, CreatedAt);
CREATE NONCLUSTERED INDEX IX_PerformanceMetrics_ExecutionTimeMs ON dbo.PerformanceMetrics (ExecutionTimeMs);
CREATE NONCLUSTERED INDEX IX_PerformanceMetrics_Success_CreatedAt ON dbo.PerformanceMetrics (Success, CreatedAt);

-- LogError procedure
IF OBJECT_ID('dbo.LogError', 'P') IS NOT NULL DROP PROCEDURE dbo.LogError;
GO

CREATE PROCEDURE dbo.LogError
    @ProcedureName NVARCHAR(100),
    @ErrorNumber INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @ErrorSeverity INT = NULL,
    @ErrorState INT = NULL,
    @ErrorLine INT = NULL,
    @Parameters NVARCHAR(MAX) = NULL,
    @StackTrace NVARCHAR(MAX) = NULL,
    @UserId UNIQUEIDENTIFIER = NULL,
    @SessionId NVARCHAR(100) = NULL,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ErrorLog (
        ProcedureName, ErrorNumber, ErrorMessage, ErrorSeverity,
        ErrorState, ErrorLine, Parameters, StackTrace,
        UserId, SessionId, IpAddress, UserAgent
    )
    VALUES (
        @ProcedureName,
        ISNULL(@ErrorNumber, ERROR_NUMBER()),
        ISNULL(@ErrorMessage, ERROR_MESSAGE()),
        ISNULL(@ErrorSeverity, ERROR_SEVERITY()),
        ISNULL(@ErrorState, ERROR_STATE()),
        ISNULL(@ErrorLine, ERROR_LINE()),
        @Parameters, @StackTrace, @UserId, @SessionId, @IpAddress, @UserAgent
    );
END;
GO

-- LogPerformance procedure
IF OBJECT_ID('dbo.LogPerformance', 'P') IS NOT NULL DROP PROCEDURE dbo.LogPerformance;
GO

CREATE PROCEDURE dbo.LogPerformance
    @OperationName NVARCHAR(100),
    @OperationType NVARCHAR(50),
    @ExecutionTimeMs INT,
    @CpuTimeMs INT = NULL,
    @MemoryUsageMB DECIMAL(10,2) = NULL,
    @RowsAffected INT = NULL,
    @DatabaseName NVARCHAR(100) = NULL,
    @UserId UNIQUEIDENTIFIER = NULL,
    @SessionId NVARCHAR(100) = NULL,
    @Parameters NVARCHAR(MAX) = NULL,
    @Success BIT = 1,
    @ErrorMessage NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Only log if performance monitoring is enabled
    DECLARE @EnableMetrics BIT = 0;
    SELECT @EnableMetrics = CASE WHEN dbo.GetConfigValue('Monitoring.EnableMetrics') = '1' THEN 1 ELSE 0 END;

    IF @EnableMetrics = 1
    BEGIN
        INSERT INTO dbo.PerformanceMetrics (
            OperationName, OperationType, ExecutionTimeMs, CpuTimeMs,
            MemoryUsageMB, RowsAffected, DatabaseName, UserId, SessionId,
            Parameters, Success, ErrorMessage
        )
        VALUES (
            @OperationName, @OperationType, @ExecutionTimeMs, @CpuTimeMs,
            @MemoryUsageMB, @RowsAffected,
            ISNULL(@DatabaseName, DB_NAME()), @UserId, @SessionId,
            @Parameters, @Success, @ErrorMessage
        );
    END
END;
GO

PRINT 'V003: Logging Infrastructure - Completed Successfully';
GO