-- ============================================================================
-- SP_VerifyPhoneForSecretKeyRecovery - Verify phone for secret key recovery
-- ============================================================================
-- Purpose: Checks if a phone number is eligible for secret key recovery
-- Author: MrReptile
-- Created: 2025-09-25
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_VerifyMobileForSecretKeyRecovery
    @MobileNumber NVARCHAR(18),
    @Region NVARCHAR(2) = NULL,
    @MobileNumberUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Outcome NVARCHAR(50) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HasSecureKey BIT = 0;
    DECLARE @MembershipStatus NVARCHAR(20);
    DECLARE @CreationStatus NVARCHAR(20);

    SET @MobileNumberUniqueId = NULL;
    SET @Outcome = 'invalid';
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Find phone number
        SELECT @MobileNumberUniqueId = UniqueId
        FROM dbo.PhoneNumbers
        WHERE PhoneNumber = @MobileNumber
          AND (Region = @Region OR (Region IS NULL AND @Region IS NULL))
          AND IsDeleted = 0;

        IF @MobileNumberUniqueId IS NULL
        BEGIN
            SET @Outcome = 'phone_not_found';
            SET @ErrorMessage = 'Phone number not found';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Find active membership for this phone number
        SELECT TOP 1
            @MembershipStatus = Status,
            @CreationStatus = CreationStatus,
            @HasSecureKey = CASE WHEN SecureKey IS NOT NULL AND DATALENGTH(SecureKey) > 0 THEN 1 ELSE 0 END
        FROM dbo.Memberships
        WHERE PhoneNumberId = @MobileNumberUniqueId
          AND IsDeleted = 0
        ORDER BY CreatedAt DESC;

        IF @MembershipStatus IS NULL
        BEGIN
            SET @Outcome = 'membership_not_found';
            SET @ErrorMessage = 'No membership found for this phone number';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Check for secure key
        IF @HasSecureKey = 0
        BEGIN
            SET @Outcome = 'no_secure_key';
            SET @ErrorMessage = 'No secure key found for this membership';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 4. Check membership status
        IF @MembershipStatus = 'blocked'
        BEGIN
            SET @Outcome = 'membership_blocked';
            SET @ErrorMessage = 'Membership is blocked';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 5. Success
        SET @Outcome = 'eligible_for_recovery';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log the error
        EXEC dbo.SP_LogEvent
            @EventType = 'secret_key_recovery_error',
            @Severity = 'error',
            @Message = 'Error during secret key recovery eligibility check',
            @Details = @ErrorMessage;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO

