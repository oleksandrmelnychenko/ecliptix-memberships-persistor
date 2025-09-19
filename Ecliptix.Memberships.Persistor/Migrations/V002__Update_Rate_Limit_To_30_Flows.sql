/*
================================================================================
V002: Update Global Rate Limit to 30 Flows Per Hour
================================================================================
Purpose: Increase verification flow rate limit from 5 to 30 flows per hour per phone number
Author: Oleksandr Melnychenko
Created: 2025-09-15
================================================================================
Changes:
- Update @MaxFlowsPerHour from 5 to 30 in InitiateVerificationFlow procedure
- This allows more verification attempts while maintaining reasonable limits
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '🔄 Starting V002: Update Rate Limit to 30 Flows Per Hour';
GO

-- ============================================================================
-- UPDATE InitiateVerificationFlow PROCEDURE
-- ============================================================================
PRINT '📈 Updating InitiateVerificationFlow procedure with new rate limit...';
GO

-- Drop existing procedure
IF OBJECT_ID('dbo.InitiateVerificationFlow', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InitiateVerificationFlow;
GO

-- Recreate procedure with updated rate limit
CREATE PROCEDURE dbo.InitiateVerificationFlow
    @PhoneNumber NVARCHAR(18),
    @Region NVARCHAR(2),
    @AppDeviceId UNIQUEIDENTIFIER,
    @Purpose NVARCHAR(30) = 'unspecified',
    @ConnectionId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PhoneNumberId BIGINT;
    DECLARE @FlowUniqueId UNIQUEIDENTIFIER;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Отримання або створення номера телефону
        EXEC dbo.EnsurePhoneNumber @PhoneNumber, @Region, @PhoneNumberId OUTPUT;

        -- 2. Перевірка на наявність активного потоку для цього пристрою та номера
        IF EXISTS (
            SELECT 1 FROM dbo.VerificationFlows
            WHERE AppDeviceId = @AppDeviceId
              AND PhoneNumberId = @PhoneNumberId
              AND Purpose = @Purpose
              AND Status = 'pending'
              AND IsDeleted = 0
        )
        BEGIN
            SELECT 'active_flow_exists' AS Outcome;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Глобальний Rate Limiting - UPDATED TO 30 FLOWS PER HOUR
        DECLARE @MaxFlowsPerHour INT = 30;
        IF (SELECT COUNT(*) FROM dbo.VerificationFlows WHERE PhoneNumberId = @PhoneNumberId AND CreatedAt > DATEADD(hour, -1, GETUTCDATE())) >= @MaxFlowsPerHour
        BEGIN
            SELECT 'global_rate_limit_exceeded' AS Outcome;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 4. Створення нового потоку верифікації
        SET @FlowUniqueId = NEWID();
        INSERT INTO dbo.VerificationFlows (
            PhoneNumberId, AppDeviceId, Status, Purpose, ExpiresAt,
            OtpCount, ConnectionId, UniqueId
        )
        VALUES (
            @PhoneNumberId, @AppDeviceId, 'pending', @Purpose,
            DATEADD(minute, 15, GETUTCDATE()), 0, @ConnectionId, @FlowUniqueId
        );

        COMMIT TRANSACTION;

        -- 5. Повернення результату
        SELECT 'success' AS Outcome, @FlowUniqueId AS FlowUniqueId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        INSERT INTO dbo.EventLog (EventType, Message)
        VALUES ('ERROR', 'InitiateVerificationFlow failed: ' + @ErrorMessage);

        SELECT 'error' AS Outcome, @ErrorMessage AS ErrorMessage;
    END CATCH
END;
GO

PRINT '✅ InitiateVerificationFlow procedure updated with rate limit: 30 flows per hour';
GO

-- ============================================================================
-- MIGRATION COMPLETION
-- ============================================================================
PRINT '';
PRINT '🎉 V002: Rate Limit Update Completed Successfully!';
PRINT '';
PRINT '📊 Changes Applied:';
PRINT '   • Global rate limit increased from 5 to 30 flows per hour per phone number';
PRINT '   • InitiateVerificationFlow procedure updated';
PRINT '   • Rate limiting logic preserved with new threshold';
PRINT '';
PRINT '✅ Users can now initiate up to 30 verification flows per hour per phone number';
GO