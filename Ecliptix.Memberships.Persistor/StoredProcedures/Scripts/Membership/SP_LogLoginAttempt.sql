-- =============================================================================
-- Procedure: LogLoginAttempt
-- Purpose: Records a login attempt for a phone number in the LoginAttempts table.
-- Author: MrReptile
-- Created: 2025-09-23
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_LogLoginAttempt
    @PhoneNumber NVARCHAR(18),
    @Outcome NVARCHAR(MAX),
    @IsSuccess BIT
    AS
BEGIN
    SET NOCOUNT ON;
INSERT INTO dbo.LoginAttempts (Timestamp, PhoneNumber, Outcome, IsSuccess)
VALUES (GETUTCDATE(), @PhoneNumber, @Outcome, @IsSuccess);
END;
GO