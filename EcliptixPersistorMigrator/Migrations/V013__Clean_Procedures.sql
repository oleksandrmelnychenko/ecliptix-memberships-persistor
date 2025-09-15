USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('dbo.create_user_account', 'P') IS NOT NULL
    DROP PROCEDURE dbo.create_user_account;
GO

CREATE PROCEDURE dbo.create_user_account
    @mobile_number NVARCHAR(20),
    @country_code NVARCHAR(3),
    @region NVARCHAR(10),
    @user_id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @user_id = NEWSEQUENTIALID();

    INSERT INTO dbo.user_account (id, mobile_number, country_code, region)
    VALUES (@user_id, @mobile_number, @country_code, @region);
END;
GO

IF OBJECT_ID('dbo.get_user_by_mobile', 'P') IS NOT NULL
    DROP PROCEDURE dbo.get_user_by_mobile;
GO

CREATE PROCEDURE dbo.get_user_by_mobile
    @mobile_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT id, mobile_number, country_code, region, is_active, created_at, updated_at
    FROM dbo.user_account
    WHERE mobile_number = @mobile_number AND is_active = 1;
END;
GO

IF OBJECT_ID('dbo.create_verification_flow', 'P') IS NOT NULL
    DROP PROCEDURE dbo.create_verification_flow;
GO

CREATE PROCEDURE dbo.create_verification_flow
    @user_account_id UNIQUEIDENTIFIER,
    @flow_type NVARCHAR(50),
    @expires_minutes INT = 10,
    @flow_id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @flow_id = NEWSEQUENTIALID();

    INSERT INTO dbo.verification_flow (id, user_account_id, flow_type, status, expires_at)
    VALUES (@flow_id, @user_account_id, @flow_type, 'PENDING', DATEADD(MINUTE, @expires_minutes, GETUTCDATE()));
END;
GO

IF OBJECT_ID('dbo.create_otp_code', 'P') IS NOT NULL
    DROP PROCEDURE dbo.create_otp_code;
GO

CREATE PROCEDURE dbo.create_otp_code
    @verification_flow_id UNIQUEIDENTIFIER,
    @code_value NVARCHAR(10),
    @expires_minutes INT = 5,
    @otp_id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @otp_id = NEWSEQUENTIALID();

    INSERT INTO dbo.otp_code (id, verification_flow_id, code_value, expires_at)
    VALUES (@otp_id, @verification_flow_id, @code_value, DATEADD(MINUTE, @expires_minutes, GETUTCDATE()));
END;
GO

IF OBJECT_ID('dbo.verify_otp_code', 'P') IS NOT NULL
    DROP PROCEDURE dbo.verify_otp_code;
GO

CREATE PROCEDURE dbo.verify_otp_code
    @verification_flow_id UNIQUEIDENTIFIER,
    @code_value NVARCHAR(10),
    @is_valid BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @otp_id UNIQUEIDENTIFIER;
    SET @is_valid = 0;

    SELECT @otp_id = id
    FROM dbo.otp_code
    WHERE verification_flow_id = @verification_flow_id
    AND code_value = @code_value
    AND is_used = 0
    AND expires_at > GETUTCDATE();

    IF @otp_id IS NOT NULL
    BEGIN
        UPDATE dbo.otp_code
        SET is_used = 1, used_at = GETUTCDATE()
        WHERE id = @otp_id;

        UPDATE dbo.verification_flow
        SET status = 'COMPLETED', completed_at = GETUTCDATE()
        WHERE id = @verification_flow_id;

        SET @is_valid = 1;
    END
    ELSE
    BEGIN
        UPDATE dbo.verification_flow
        SET attempt_count = attempt_count + 1
        WHERE id = @verification_flow_id;
    END
END;
GO

IF OBJECT_ID('dbo.create_authentication_session', 'P') IS NOT NULL
    DROP PROCEDURE dbo.create_authentication_session;
GO

CREATE PROCEDURE dbo.create_authentication_session
    @user_account_id UNIQUEIDENTIFIER,
    @device_info NVARCHAR(500) = NULL,
    @ip_address NVARCHAR(45) = NULL,
    @expires_days INT = 30,
    @session_id UNIQUEIDENTIFIER OUTPUT,
    @session_token NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @session_id = NEWSEQUENTIALID();
    SET @session_token = CONVERT(NVARCHAR(255), @session_id);

    INSERT INTO dbo.authentication_session (id, user_account_id, session_token, device_info, ip_address, expires_at)
    VALUES (@session_id, @user_account_id, @session_token, @device_info, @ip_address, DATEADD(DAY, @expires_days, GETUTCDATE()));
END;
GO

IF OBJECT_ID('dbo.validate_session_token', 'P') IS NOT NULL
    DROP PROCEDURE dbo.validate_session_token;
GO

CREATE PROCEDURE dbo.validate_session_token
    @session_token NVARCHAR(255),
    @user_account_id UNIQUEIDENTIFIER OUTPUT,
    @is_valid BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @is_valid = 0;
    SET @user_account_id = NULL;

    SELECT @user_account_id = user_account_id
    FROM dbo.authentication_session
    WHERE session_token = @session_token
    AND is_active = 1
    AND expires_at > GETUTCDATE();

    IF @user_account_id IS NOT NULL
        SET @is_valid = 1;
END;
GO

IF OBJECT_ID('dbo.expire_session', 'P') IS NOT NULL
    DROP PROCEDURE dbo.expire_session;
GO

CREATE PROCEDURE dbo.expire_session
    @session_token NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.authentication_session
    SET is_active = 0
    WHERE session_token = @session_token;
END;
GO

IF OBJECT_ID('dbo.cleanup_expired_data', 'P') IS NOT NULL
    DROP PROCEDURE dbo.cleanup_expired_data;
GO

CREATE PROCEDURE dbo.cleanup_expired_data
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.otp_code
    WHERE expires_at < DATEADD(DAY, -1, GETUTCDATE());

    DELETE FROM dbo.verification_flow
    WHERE expires_at < DATEADD(DAY, -1, GETUTCDATE())
    AND status IN ('EXPIRED', 'FAILED');

    UPDATE dbo.authentication_session
    SET is_active = 0
    WHERE expires_at < GETUTCDATE()
    AND is_active = 1;
END;
GO

PRINT 'V013: Clean Procedures - Completed Successfully';
GO