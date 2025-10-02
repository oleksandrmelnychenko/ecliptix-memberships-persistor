-- ============================================================================
-- SP_LoginMembership - Membership login with rate limiting and lockout
-- ============================================================================
-- Purpose: Handles membership login with rate limiting, lockout, and logging
-- Author: MrReptile
-- Created: 2025-09-22
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_LoginMembership
    @MobileNumber NVARCHAR(18),
    @MembershipUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Status NVARCHAR(20) OUTPUT,
    @Outcome NVARCHAR(500) OUTPUT,
    @SecureKey VARBINARY(MAX) OUTPUT,
    @MaskingKey VARBINARY(32) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNumberId UNIQUEIDENTIFIER, @CreationStatus NVARCHAR(20);
    DECLARE @CurrentTime DATETIME2(7) = GETUTCDATE();
    DECLARE @AttemptsInLast5Minutes INT;
    DECLARE @LockoutDurationMinutes INT = 5;
    DECLARE @MaxAttemptsInPeriod INT = 5;
    DECLARE @LockoutMarkerPrefix NVARCHAR(20) = 'LOCKED_UNTIL:';
    DECLARE @LockedUntilTs DATETIME2(7);
    DECLARE @LastLockoutInitTime DATETIME2(7);
    DECLARE @LockoutMarkerOutcome NVARCHAR(MAX);
    DECLARE @LockoutPattern NVARCHAR(30) = @LockoutMarkerPrefix + '%';

    -- Initialize outputs
    SET @MembershipUniqueId = NULL;
    SET @Status = NULL;
    SET @Outcome = NULL;
    SET @SecureKey = NULL;
    SET @MaskingKey = NULL;
    SET @ErrorMessage = NULL;

    BEGIN TRY
        -- 1. Check for active lockout
        SELECT TOP 1 @LockoutMarkerOutcome = Outcome, @LastLockoutInitTime = Timestamp
        FROM dbo.LoginAttempts
        WHERE MobileNumber = @MobileNumber AND Outcome LIKE @LockoutPattern
        ORDER BY Timestamp DESC;

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
                RETURN;
            END
            ELSE IF @LockedUntilTs IS NOT NULL AND @CurrentTime >= @LockedUntilTs
            BEGIN
                DELETE FROM dbo.LoginAttempts
                WHERE MobileNumber = @MobileNumber
                AND Timestamp <= @LastLockoutInitTime;
            END
        END

        -- 2. Count attempts in last 5 minutes (excluding lockout markers)
        SELECT @AttemptsInLast5Minutes = COUNT(*)
        FROM dbo.LoginAttempts
        WHERE MobileNumber = @MobileNumber
        AND Timestamp > DATEADD(minute, -5, @CurrentTime)
        AND Outcome NOT LIKE @LockoutPattern;

        -- 3. Check if attempts exceed limit
        IF @AttemptsInLast5Minutes >= @MaxAttemptsInPeriod
        BEGIN
            SET @LockedUntilTs = DATEADD(minute, @LockoutDurationMinutes, @CurrentTime);
            DECLARE @NewLockoutMarker NVARCHAR(MAX) = CONCAT(@LockoutMarkerPrefix, CONVERT(NVARCHAR(30), @LockedUntilTs, 127));
            EXEC dbo.SP_LogLoginAttempt @MobileNumber, @NewLockoutMarker, 0;
            SET @Outcome = CAST(@LockoutDurationMinutes AS NVARCHAR(100));
            RETURN;
        END

        -- 4. Login attempt logic
        IF @MobileNumber IS NULL OR @MobileNumber = ''
            SET @Outcome = 'mobile_number_cannot_be_empty';
        ELSE
        BEGIN
            SELECT @MobileNumberId = UniqueId
            FROM dbo.MobileNumbers
            WHERE Number = @MobileNumber AND IsDeleted = 0;

            IF @MobileNumberId IS NULL
                SET @Outcome = 'mobile_number_not_found';
            ELSE
            BEGIN
                SELECT TOP 1 @MembershipUniqueId = UniqueId,
                            @SecureKey = SecureKey,
                            @MaskingKey = MaskingKey,
                            @Status = Status,
                            @CreationStatus = CreationStatus
                FROM dbo.Memberships
                WHERE MobileNumberId = @MobileNumberId
                AND IsDeleted = 0
                ORDER BY CreatedAt DESC;

                IF @MembershipUniqueId IS NULL
                    SET @Outcome = 'membership_not_found';
                ELSE IF @SecureKey IS NULL
                    SET @Outcome = 'secure_key_not_set';
                ELSE IF @Status != 'active'
                    SET @Outcome = 'inactive_membership';
                ELSE
                    SET @Outcome = 'success';
            END
        END

        -- 5. Handle result and logging
        IF @Outcome = 'success'
        BEGIN
            EXEC dbo.SP_LogLoginAttempt @MobileNumber, @Outcome, 1;
            DELETE FROM dbo.LoginAttempts
            WHERE MobileNumber = @MobileNumber
            AND (IsSuccess = 0 OR Outcome LIKE @LockoutPattern);
        END
        ELSE
        BEGIN
            EXEC dbo.SP_LogLoginAttempt @MobileNumber, @Outcome, 0;
            SET @MembershipUniqueId = NULL;
            SET @Status = NULL;
            SET @SecureKey = NULL;
            SET @MaskingKey = NULL;
        END
    END TRY
    BEGIN CATCH
        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END
GO

