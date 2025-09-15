/*
================================================================================
V004: Authentication Procedures
================================================================================
Purpose: Core authentication context management procedures with enhanced security
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- CreateAuthContext procedure
IF OBJECT_ID('dbo.CreateAuthContext', 'P') IS NOT NULL DROP PROCEDURE dbo.CreateAuthContext;
GO

CREATE PROCEDURE dbo.CreateAuthContext
    @MemberId UNIQUEIDENTIFIER,
    @DeviceIdentifier NVARCHAR(255) = NULL,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL,
    @ExpirationHours INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(7) = GETUTCDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Get configuration values
        DECLARE @DefaultExpirationHours INT = CAST(dbo.GetConfigValue('Authentication.ContextExpirationHours') AS INT);
        DECLARE @MaxSessionsPerUser INT = CAST(dbo.GetConfigValue('Authentication.MaxSessionsPerUser') AS INT);

        -- Calculate expiration time
        DECLARE @ExpiresAt DATETIME2(7) = DATEADD(HOUR, ISNULL(@ExpirationHours, @DefaultExpirationHours), GETUTCDATE());

        -- Clean up expired sessions for this user
        DELETE FROM dbo.AuthenticationContexts
        WHERE MemberId = @MemberId AND ExpiresAt < GETUTCDATE();

        -- Check active session limit
        DECLARE @ActiveSessionCount INT;
        SELECT @ActiveSessionCount = COUNT(*)
        FROM dbo.AuthenticationContexts
        WHERE MemberId = @MemberId AND IsActive = 1 AND ExpiresAt > GETUTCDATE();

        IF @ActiveSessionCount >= @MaxSessionsPerUser
        BEGIN
            -- Remove oldest session
            DELETE TOP (1) FROM dbo.AuthenticationContexts
            WHERE MemberId = @MemberId AND IsActive = 1 AND ExpiresAt > GETUTCDATE()
            ORDER BY LastAccessedAt ASC;
        END

        -- Create new authentication context
        DECLARE @ContextId UNIQUEIDENTIFIER = NEWID();

        INSERT INTO dbo.AuthenticationContexts (
            ContextId, MemberId, DeviceIdentifier, IpAddress, UserAgent,
            ExpiresAt, LastAccessedAt
        )
        VALUES (
            @ContextId, @MemberId, @DeviceIdentifier, @IpAddress, @UserAgent,
            @ExpiresAt, GETUTCDATE()
        );

        -- Log successful creation
        INSERT INTO dbo.AuditLog (
            EntityType, EntityId, Operation, NewValues,
            IpAddress, UserAgent, CreatedBy
        )
        VALUES (
            'AuthenticationContext', CAST(@ContextId AS NVARCHAR(50)), 'INSERT',
            JSON_OBJECT('MemberId', @MemberId, 'ExpiresAt', @ExpiresAt),
            @IpAddress, @UserAgent, 'SYSTEM'
        );

        COMMIT TRANSACTION;

        -- Log performance
        DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
        EXEC dbo.LogPerformance
            @OperationName = 'CreateAuthContext',
            @OperationType = 'INSERT',
            @ExecutionTimeMs = @Duration,
            @RowsAffected = 1,
            @Success = 1;

        SELECT
            @ContextId AS ContextId,
            @ExpiresAt AS ExpiresAt,
            1 AS Success,
            'Authentication context created successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        EXEC dbo.LogError
            @ProcedureName = 'CreateAuthContext',
            @Parameters = JSON_OBJECT('MemberId', @MemberId, 'DeviceIdentifier', @DeviceIdentifier);

        SELECT
            NULL AS ContextId,
            NULL AS ExpiresAt,
            0 AS Success,
            ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

-- ValidateAuthContext procedure
IF OBJECT_ID('dbo.ValidateAuthContext', 'P') IS NOT NULL DROP PROCEDURE dbo.ValidateAuthContext;
GO

CREATE PROCEDURE dbo.ValidateAuthContext
    @ContextId UNIQUEIDENTIFIER,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(7) = GETUTCDATE();

    BEGIN TRY
        DECLARE @MemberId UNIQUEIDENTIFIER;
        DECLARE @ExpiresAt DATETIME2(7);
        DECLARE @IsActive BIT;

        -- Get context details
        SELECT
            @MemberId = MemberId,
            @ExpiresAt = ExpiresAt,
            @IsActive = IsActive
        FROM dbo.AuthenticationContexts
        WHERE ContextId = @ContextId;

        -- Check if context exists
        IF @MemberId IS NULL
        BEGIN
            SELECT 0 AS IsValid, 'Authentication context not found' AS Message;
            RETURN;
        END

        -- Check if context is expired
        IF @ExpiresAt <= GETUTCDATE()
        BEGIN
            -- Mark as inactive
            UPDATE dbo.AuthenticationContexts
            SET IsActive = 0, UpdatedAt = GETUTCDATE()
            WHERE ContextId = @ContextId;

            SELECT 0 AS IsValid, 'Authentication context has expired' AS Message;
            RETURN;
        END

        -- Check if context is active
        IF @IsActive = 0
        BEGIN
            SELECT 0 AS IsValid, 'Authentication context is not active' AS Message;
            RETURN;
        END

        -- Update last accessed time
        UPDATE dbo.AuthenticationContexts
        SET LastAccessedAt = GETUTCDATE(),
            IpAddress = ISNULL(@IpAddress, IpAddress),
            UserAgent = ISNULL(@UserAgent, UserAgent)
        WHERE ContextId = @ContextId;

        -- Log performance
        DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
        EXEC dbo.LogPerformance
            @OperationName = 'ValidateAuthContext',
            @OperationType = 'SELECT',
            @ExecutionTimeMs = @Duration,
            @RowsAffected = 1,
            @Success = 1;

        SELECT
            1 AS IsValid,
            'Authentication context is valid' AS Message,
            @MemberId AS MemberId;

    END TRY
    BEGIN CATCH
        EXEC dbo.LogError
            @ProcedureName = 'ValidateAuthContext',
            @Parameters = JSON_OBJECT('ContextId', @ContextId);

        SELECT
            0 AS IsValid,
            ERROR_MESSAGE() AS Message,
            NULL AS MemberId;
    END CATCH
END;
GO

-- DeactivateAuthContext procedure
IF OBJECT_ID('dbo.DeactivateAuthContext', 'P') IS NOT NULL DROP PROCEDURE dbo.DeactivateAuthContext;
GO

CREATE PROCEDURE dbo.DeactivateAuthContext
    @ContextId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(7) = GETUTCDATE();

    BEGIN TRY
        UPDATE dbo.AuthenticationContexts
        SET IsActive = 0,
            UpdatedAt = GETUTCDATE()
        WHERE ContextId = @ContextId;

        -- Log audit
        INSERT INTO dbo.AuditLog (
            EntityType, EntityId, Operation, NewValues, CreatedBy
        )
        VALUES (
            'AuthenticationContext', CAST(@ContextId AS NVARCHAR(50)), 'UPDATE',
            JSON_OBJECT('IsActive', 0), 'SYSTEM'
        );

        -- Log performance
        DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());
        EXEC dbo.LogPerformance
            @OperationName = 'DeactivateAuthContext',
            @OperationType = 'UPDATE',
            @ExecutionTimeMs = @Duration,
            @RowsAffected = @@ROWCOUNT,
            @Success = 1;

        SELECT
            1 AS Success,
            'Authentication context deactivated successfully' AS Message;

    END TRY
    BEGIN CATCH
        EXEC dbo.LogError
            @ProcedureName = 'DeactivateAuthContext',
            @Parameters = JSON_OBJECT('ContextId', @ContextId);

        SELECT
            0 AS Success,
            ERROR_MESSAGE() AS Message;
    END CATCH
END;
GO

PRINT 'V004: Authentication Procedures - Completed Successfully';
GO