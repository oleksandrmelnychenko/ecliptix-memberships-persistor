USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DROP TABLE IF EXISTS dbo.otp_code;
DROP TABLE IF EXISTS dbo.verification_flow;
DROP TABLE IF EXISTS dbo.authentication_session;
DROP TABLE IF EXISTS dbo.user_account;
GO

CREATE TABLE dbo.user_account (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    mobile_number NVARCHAR(20) NOT NULL,
    country_code NVARCHAR(3) NOT NULL,
    region NVARCHAR(10) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT uq_user_account_mobile_number UNIQUE (mobile_number)
);
GO

CREATE TABLE dbo.authentication_session (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    user_account_id UNIQUEIDENTIFIER NOT NULL,
    session_token NVARCHAR(255) NOT NULL,
    device_info NVARCHAR(500),
    ip_address NVARCHAR(45),
    is_active BIT NOT NULL DEFAULT 1,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT fk_authentication_session_user_account
        FOREIGN KEY (user_account_id) REFERENCES dbo.user_account(id),
    CONSTRAINT uq_authentication_session_token UNIQUE (session_token)
);
GO

CREATE TABLE dbo.verification_flow (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    user_account_id UNIQUEIDENTIFIER NOT NULL,
    flow_type NVARCHAR(50) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    attempt_count INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    completed_at DATETIME2,
    CONSTRAINT fk_verification_flow_user_account
        FOREIGN KEY (user_account_id) REFERENCES dbo.user_account(id)
);
GO

CREATE TABLE dbo.otp_code (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    verification_flow_id UNIQUEIDENTIFIER NOT NULL,
    code_value NVARCHAR(10) NOT NULL,
    is_used BIT NOT NULL DEFAULT 0,
    expires_at DATETIME2 NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    used_at DATETIME2,
    CONSTRAINT fk_otp_code_verification_flow
        FOREIGN KEY (verification_flow_id) REFERENCES dbo.verification_flow(id)
);
GO

CREATE INDEX ix_user_account_mobile_number ON dbo.user_account (mobile_number);
CREATE INDEX ix_authentication_session_user_account_id ON dbo.authentication_session (user_account_id);
CREATE INDEX ix_authentication_session_expires_at ON dbo.authentication_session (expires_at);
CREATE INDEX ix_verification_flow_user_account_id ON dbo.verification_flow (user_account_id);
CREATE INDEX ix_verification_flow_status ON dbo.verification_flow (status);
CREATE INDEX ix_otp_code_verification_flow_id ON dbo.otp_code (verification_flow_id);
CREATE INDEX ix_otp_code_expires_at ON dbo.otp_code (expires_at);
GO

INSERT INTO dbo.user_account (id, mobile_number, country_code, region, is_active, created_at, updated_at)
SELECT
    COALESCE(pn.UniqueId, NEWID()),
    pn.PhoneNumber,
    COALESCE(pn.CountryCode, '+1'),
    COALESCE(pn.Region, 'US'),
    CASE WHEN pn.IsActive = 1 THEN 1 ELSE 0 END,
    COALESCE(pn.CreatedAt, GETUTCDATE()),
    COALESCE(pn.UpdatedAt, GETUTCDATE())
FROM dbo.PhoneNumbers pn
WHERE pn.PhoneNumber IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM dbo.user_account ua
    WHERE ua.mobile_number = pn.PhoneNumber
);
GO

INSERT INTO dbo.authentication_session (id, user_account_id, session_token, device_info, ip_address, is_active, expires_at, created_at)
SELECT
    COALESCE(ac.UniqueId, NEWID()),
    ua.id,
    COALESCE(ac.SessionToken, CONVERT(NVARCHAR(255), NEWID())),
    COALESCE(ac.DeviceInfo, 'Unknown'),
    ac.IPAddress,
    CASE WHEN ac.IsActive = 1 THEN 1 ELSE 0 END,
    COALESCE(ac.ExpiresAt, DATEADD(DAY, 30, GETUTCDATE())),
    COALESCE(ac.CreatedAt, GETUTCDATE())
FROM dbo.AuthenticationContexts ac
INNER JOIN dbo.user_account ua ON ua.mobile_number = (
    SELECT TOP 1 pn.PhoneNumber
    FROM dbo.PhoneNumbers pn
    WHERE pn.UniqueId = ac.PhoneNumberId
)
WHERE ac.SessionToken IS NOT NULL;
GO

INSERT INTO dbo.verification_flow (id, user_account_id, flow_type, status, attempt_count, max_attempts, expires_at, created_at, completed_at)
SELECT
    COALESCE(vf.FlowId, NEWID()),
    ua.id,
    COALESCE(vf.FlowType, 'PHONE_VERIFICATION'),
    COALESCE(vf.Status, 'PENDING'),
    COALESCE(vf.AttemptCount, 0),
    COALESCE(vf.MaxAttempts, 5),
    COALESCE(vf.ExpiresAt, DATEADD(MINUTE, 10, GETUTCDATE())),
    COALESCE(vf.CreatedAt, GETUTCDATE()),
    vf.CompletedAt
FROM dbo.VerificationFlows vf
INNER JOIN dbo.user_account ua ON ua.mobile_number = (
    SELECT TOP 1 pn.PhoneNumber
    FROM dbo.PhoneNumbers pn
    WHERE pn.UniqueId = vf.PhoneNumberId
);
GO

INSERT INTO dbo.otp_code (id, verification_flow_id, code_value, is_used, expires_at, created_at, used_at)
SELECT
    COALESCE(otr.UniqueId, NEWID()),
    vf.id,
    otr.Code,
    CASE WHEN otr.IsUsed = 1 THEN 1 ELSE 0 END,
    COALESCE(otr.ExpiresAt, DATEADD(MINUTE, 5, GETUTCDATE())),
    COALESCE(otr.CreatedAt, GETUTCDATE()),
    otr.UsedAt
FROM dbo.OtpRecords otr
INNER JOIN dbo.verification_flow vf ON vf.id = (
    SELECT TOP 1 vf2.id
    FROM dbo.verification_flow vf2
    INNER JOIN dbo.user_account ua ON ua.id = vf2.user_account_id
    WHERE ua.mobile_number = (
        SELECT TOP 1 pn.PhoneNumber
        FROM dbo.PhoneNumbers pn
        WHERE pn.UniqueId = otr.PhoneNumberId
    )
)
WHERE otr.Code IS NOT NULL;
GO

PRINT 'V012: Clean Schema Migration - Completed Successfully';
GO