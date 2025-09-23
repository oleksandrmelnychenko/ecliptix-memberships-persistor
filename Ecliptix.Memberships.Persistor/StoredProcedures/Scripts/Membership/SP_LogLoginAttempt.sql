-- =============================================================================
-- Procedure: LogLoginAttempt
-- Purpose: Records a login attempt for a mobile number in the LoginAttempts table.
-- Author: MrReptile
-- Created: 2025-09-23
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_LogLoginAttempt
    @MobileNumber NVARCHAR(18),
    @Outcome NVARCHAR(MAX),
    @IsSuccess BIT
    AS
BEGIN
    SET NOCOUNT ON;
INSERT INTO dbo.LoginAttempts (Timestamp, MobileNumber, Outcome, IsSuccess)
VALUES (GETUTCDATE(), @MobileNumber, @Outcome, @IsSuccess);
END;
GO