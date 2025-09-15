-- ============================================
-- Object: LoginMembership Procedure
-- Type: Membership Procedure
-- Purpose: Authenticates users with advanced lockout protection and secure key retrieval
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers, Memberships, LoginAttempts tables, LogLoginAttempt procedure
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.LoginMembership', 'P') IS NOT NULL
    DROP PROCEDURE dbo.LoginMembership;
GO

-- Create LoginMembership procedure
-- Authenticates users with lockout logic and returns SecureKey on success
CREATE PROCEDURE dbo.LoginMembership
    @PhoneNumber NVARCHAR(18)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MembershipUniqueId UNIQUEIDENTIFIER, @Status NVARCHAR(20), @Outcome NVARCHAR(100);
    DECLARE @PhoneNumberId UNIQUEIDENTIFIER, @StoredSecureKey VARBINARY(MAX), @CreationStatus NVARCHAR(20);
    DECLARE @CurrentTime DATETIME2(7) = GETUTCDATE();
    DECLARE @AttemptsInLast5Minutes INT;
    DECLARE @LockoutDurationMinutes INT = 5;
    DECLARE @MaxAttemptsInPeriod INT = 5;
    DECLARE @LockoutMarkerPrefix NVARCHAR(20) = 'LOCKED_UNTIL:';
    DECLARE @LockedUntilTs DATETIME2(7);
    DECLARE @LastLockoutInitTime DATETIME2(7);
    DECLARE @LockoutMarkerOutcome NVARCHAR(MAX);
    DECLARE @LockoutPattern NVARCHAR(30) = @LockoutMarkerPrefix + '%';

    -- 1. Check for active lockout
    SELECT TOP 1 @LockoutMarkerOutcome = Outcome, @LastLockoutInitTime = Timestamp
    FROM dbo.LoginAttempts
    WHERE PhoneNumber = @PhoneNumber AND Outcome LIKE @LockoutPattern
    ORDER BY Timestamp DESC
    OPTION (MAXRECURSION 100);

    IF @LockoutMarkerOutcome IS NOT NULL
    BEGIN
        BEGIN TRY
            SET @LockedUntilTs = CAST(SUBSTRING(@LockoutMarkerOutcome, LEN(@LockoutMarkerPrefix) + 1, 100) AS DATETIME2(7));
        END TRY
        BEGIN CATCH
            SET @LockedUntilTs = NULL;
        END CATCH

        IF @LockedUntilTs IS NOT NULL AND @CurrentTime < @LockedUntilTs
        BEGIN
            SET @Outcome = CAST(CEILING(CAST(DATEDIFF(second, @CurrentTime, @LockedUntilTs) AS DECIMAL) / 60.0) AS NVARCHAR(100));
            SELECT NULL AS MembershipUniqueId, NULL AS Status, @Outcome AS Outcome, NULL AS SecureKey;
            RETURN;
        END
        ELSE IF @LockedUntilTs IS NOT NULL AND @CurrentTime >= @LockedUntilTs
        BEGIN
            DELETE FROM dbo.LoginAttempts
            WHERE PhoneNumber = @PhoneNumber
            AND Timestamp <= @LastLockoutInitTime;
        END
    END

    -- 2. Count attempts in last 5 minutes (excluding lockout markers)
    SELECT @AttemptsInLast5Minutes = COUNT(*)
    FROM dbo.LoginAttempts
    WHERE PhoneNumber = @PhoneNumber
    AND Timestamp > DATEADD(minute, -5, @CurrentTime)
    AND Outcome NOT LIKE @LockoutPattern
    OPTION (MAXRECURSION 100);

    -- 3. Check if we already have 5 attempts in last 5 minutes
    IF @AttemptsInLast5Minutes >= @MaxAttemptsInPeriod
    BEGIN
        SET @LockedUntilTs = DATEADD(minute, @LockoutDurationMinutes, @CurrentTime);
        DECLARE @NewLockoutMarker NVARCHAR(MAX) = CONCAT(@LockoutMarkerPrefix, CONVERT(NVARCHAR(30), @LockedUntilTs, 127));
        EXEC dbo.LogLoginAttempt @PhoneNumber, @NewLockoutMarker, 0;
        SET @Outcome = CAST(@LockoutDurationMinutes AS NVARCHAR(100));
        SELECT NULL AS MembershipUniqueId, NULL AS Status, @Outcome AS Outcome, NULL AS SecureKey;
        RETURN;
    END

    -- 4. Login attempt logic
    IF @PhoneNumber IS NULL OR @PhoneNumber = ''
        SET @Outcome = 'phone_number_cannot_be_empty';
    ELSE
    BEGIN
        SELECT @PhoneNumberId = UniqueId
        FROM dbo.PhoneNumbers
        WHERE PhoneNumber = @PhoneNumber AND IsDeleted = 0;

        IF @PhoneNumberId IS NULL
            SET @Outcome = 'phone_number_not_found';
        ELSE
        BEGIN
            SELECT TOP 1 @MembershipUniqueId = UniqueId,
                        @StoredSecureKey = SecureKey,
                        @Status = Status,
                        @CreationStatus = CreationStatus
            FROM dbo.Memberships
            WHERE PhoneNumberId = @PhoneNumberId
            AND IsDeleted = 0
            ORDER BY CreatedAt DESC;

            IF @MembershipUniqueId IS NULL
                SET @Outcome = 'membership_not_found';
            ELSE IF @StoredSecureKey IS NULL
                SET @Outcome = 'secure_key_not_set';
            ELSE IF @Status != 'active'
                SET @Outcome = 'inactive_membership';
            ELSE
                SET @Outcome = 'success';
        END
    END

    -- 5. Handle result
    IF @Outcome = 'success'
    BEGIN
        EXEC dbo.LogLoginAttempt @PhoneNumber, @Outcome, 1;
        DELETE FROM dbo.LoginAttempts
        WHERE PhoneNumber = @PhoneNumber
        AND (IsSuccess = 0 OR Outcome LIKE @LockoutPattern);
        SELECT @MembershipUniqueId AS MembershipUniqueId,
               @Status AS Status,
               @Outcome AS Outcome,
               @StoredSecureKey AS SecureKey;
    END
    ELSE
    BEGIN
        EXEC dbo.LogLoginAttempt @PhoneNumber, @Outcome, 0;
        SELECT NULL AS MembershipUniqueId,
               NULL AS Status,
               @Outcome AS Outcome,
               NULL AS SecureKey;
    END
END;
GO

PRINT '✅ LoginMembership procedure created successfully';
GO