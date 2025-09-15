-- ============================================
-- Object: VerifyPhoneForSecretKeyRecovery Procedure
-- Type: Core Procedure
-- Purpose: Verifies if a phone number is eligible for secure key recovery
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers, Memberships tables
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.VerifyPhoneForSecretKeyRecovery', 'P') IS NOT NULL
    DROP PROCEDURE dbo.VerifyPhoneForSecretKeyRecovery;
GO

-- Create VerifyPhoneForSecretKeyRecovery procedure
-- Verifies if a phone number can be used for secure key recovery
CREATE PROCEDURE dbo.VerifyPhoneForSecretKeyRecovery
    @PhoneNumberString NVARCHAR(18),
    @Region NVARCHAR(2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PhoneNumberId UNIQUEIDENTIFIER;
    DECLARE @HasSecureKey BIT = 0;
    DECLARE @MembershipStatus NVARCHAR(20);
    DECLARE @CreationStatus NVARCHAR(20);

    -- Find the phone number
    SELECT @PhoneNumberId = UniqueId
    FROM dbo.PhoneNumbers
    WHERE PhoneNumber = @PhoneNumberString
      AND (Region = @Region OR (Region IS NULL AND @Region IS NULL))
      AND IsDeleted = 0;

    IF @PhoneNumberId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Phone number not found' AS Message,
               'phone_not_found' AS Outcome, NULL AS PhoneNumberId;
        RETURN;
    END

    -- Find active membership for this phone number
    SELECT TOP 1
        @MembershipStatus = Status,
        @CreationStatus = CreationStatus,
        @HasSecureKey = CASE WHEN SecureKey IS NOT NULL AND DATALENGTH(SecureKey) > 0 THEN 1 ELSE 0 END
    FROM dbo.Memberships
    WHERE PhoneNumberId = @PhoneNumberId
      AND IsDeleted = 0
    ORDER BY CreatedAt DESC;

    IF @MembershipStatus IS NULL
    BEGIN
        SELECT 0 AS Success, 'No membership found for this phone number' AS Message,
               'membership_not_found' AS Outcome, @PhoneNumberId AS PhoneNumberId;
        RETURN;
    END

    -- Check if secure key exists
    IF @HasSecureKey = 0
    BEGIN
        SELECT 0 AS Success, 'No secure key found for this membership' AS Message,
               'no_secure_key' AS Outcome, @PhoneNumberId AS PhoneNumberId;
        RETURN;
    END

    -- Check membership status
    IF @MembershipStatus = 'blocked'
    BEGIN
        SELECT 0 AS Success, 'Membership is blocked' AS Message,
               'membership_blocked' AS Outcome, @PhoneNumberId AS PhoneNumberId;
        RETURN;
    END

    -- Successful verification
    SELECT 1 AS Success, 'Phone number eligible for secure key recovery' AS Message,
           'eligible_for_recovery' AS Outcome, @PhoneNumberId AS PhoneNumberUniqueId;
END;
GO

PRINT '✅ VerifyPhoneForSecretKeyRecovery procedure created successfully';
GO