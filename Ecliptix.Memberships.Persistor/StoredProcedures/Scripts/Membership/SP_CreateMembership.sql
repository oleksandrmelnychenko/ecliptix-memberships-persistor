-- ============================================================================
-- SP_CreateMembership - Create new membership with attempt limitation
-- ============================================================================
-- Purpose: Creates a new membership with rate limiting and logs all events
-- Author: MrReptile
-- Created: 2025-09-22
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_CreateMembership
    @FlowUniqueId UNIQUEIDENTIFIER,
    @ConnectionId BIGINT,
    @OtpUniqueId UNIQUEIDENTIFIER,
    @CreationStatus NVARCHAR(20),
    @MembershipUniqueId UNIQUEIDENTIFIER OUTPUT,
    @Status NVARCHAR(20) OUTPUT,
    @ResultCreationStatus NVARCHAR(20) OUTPUT,
    @Outcome NVARCHAR(100) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNumberId UNIQUEIDENTIFIER;
    DECLARE @AppDeviceId UNIQUEIDENTIFIER;
    DECLARE @ExistingMembershipId BIGINT;
    DECLARE @ExistingCreationStatus NVARCHAR(20);

    DECLARE @FailedAttempts INT;
    DECLARE @AttemptWindowHours INT = 1;
    DECLARE @MaxAttempts INT = 5;
    DECLARE @EarliestFailedAttempt DATETIME2(7);
    DECLARE @WaitMinutes INT;

    SET @MembershipUniqueId = NULL;
    SET @Status = NULL;
    SET @ResultCreationStatus = NULL;
    SET @Outcome = NULL;
    SET @ErrorMessage = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Get MobileNumberId
        SELECT @MobileNumberId = pn.UniqueId
        FROM dbo.VerificationFlows vf
            JOIN dbo.MobileNumbers pn ON vf.MobileNumberId = pn.Id
        WHERE vf.UniqueId = @FlowUniqueId AND vf.IsDeleted = 0;

        -- 2. Rate limiting check
        SELECT
            @FailedAttempts = COUNT(*),
            @EarliestFailedAttempt = MIN(ma.AttemptedAt)
        FROM dbo.MembershipAttempts ma
        INNER JOIN dbo.Memberships m ON ma.MembershipId = m.UniqueId
        WHERE m.MobileNumberId = @MobileNumberId
            AND ma.Status = 'failed'
            AND ma.AttemptedAt > DATEADD(hour, -@AttemptWindowHours, GETUTCDATE())
            AND ma.IsDeleted = 0
            AND m.IsDeleted = 0;

        IF @FailedAttempts >= @MaxAttempts
        BEGIN
            SET @WaitMinutes = DATEDIFF(minute, GETUTCDATE(), DATEADD(hour, @AttemptWindowHours, @EarliestFailedAttempt));
            SET @Outcome = CAST(CASE WHEN @WaitMinutes < 0 THEN 0 ELSE @WaitMinutes END AS NVARCHAR(100));
            -- Log attempt (rate limit exceeded)
            INSERT INTO dbo.MembershipAttempts (MembershipId, AttemptType, Status, ErrorMessage, AttemptedAt, CreatedAt, UpdatedAt, IsDeleted)
            SELECT TOP 1 m.UniqueId, 'create', 'failed', 'rate_limit_exceeded', GETUTCDATE(), GETUTCDATE(), GETUTCDATE(), 0
            FROM dbo.Memberships m
            WHERE m.MobileNumberId = @MobileNumberId AND m.IsDeleted = 0
            ORDER BY m.CreatedAt DESC;
            SET @ErrorMessage = 'rate_limit_exceeded';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Get session details
        SELECT
            @MobileNumberId = pn.UniqueId,
            @AppDeviceId = vf.AppDeviceId
        FROM dbo.VerificationFlows vf
            JOIN dbo.MobileNumbers pn ON vf.MobileNumberId = pn.Id
        WHERE vf.UniqueId = @FlowUniqueId
            AND vf.ConnectionId = @ConnectionId
            AND vf.Purpose = 'registration'
            AND vf.IsDeleted = 0
            AND pn.IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @Outcome = 'verification_flow_not_found';
            -- Log attempt (verification flow not found)
            IF @MobileNumberId IS NOT NULL
            BEGIN
                INSERT INTO dbo.MembershipAttempts (MembershipId, AttemptType, Status, ErrorMessage, AttemptedAt, CreatedAt, UpdatedAt, IsDeleted)
                SELECT TOP 1 m.UniqueId, 'create', 'failed', 'verification_flow_not_found', GETUTCDATE(), GETUTCDATE(), GETUTCDATE(), 0
                FROM dbo.Memberships m
                WHERE m.MobileNumberId = @MobileNumberId AND m.IsDeleted = 0
                ORDER BY m.CreatedAt DESC;
            END

            SET @ErrorMessage = 'verification_flow_not_found';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 4. Check for existing membership
        SELECT TOP 1
            @ExistingMembershipId = Id,
            @MembershipUniqueId = UniqueId,
            @Status = Status,
            @ExistingCreationStatus = CreationStatus
        FROM dbo.Memberships
        WHERE MobileNumberId = @MobileNumberId AND AppDeviceId = @AppDeviceId AND IsDeleted = 0;

        IF @ExistingMembershipId IS NOT NULL
        BEGIN
            SET @Outcome = 'membership_already_exists';
            -- Log attempt (success or already exists)
            INSERT INTO dbo.MembershipAttempts (MembershipId, AttemptType, Status, ErrorMessage, AttemptedAt, CreatedAt, UpdatedAt, IsDeleted)
            SELECT TOP 1 m.UniqueId, 'create', 
                CASE WHEN @Outcome = 'created' THEN 'success' ELSE 'failed' END, 
                @Outcome, GETUTCDATE(), GETUTCDATE(), GETUTCDATE(), 0
            FROM dbo.Memberships m
            WHERE m.MobileNumberId = @MobileNumberId AND m.IsDeleted = 0
            ORDER BY m.CreatedAt DESC;

            SET @ResultCreationStatus = @ExistingCreationStatus;
            SET @ErrorMessage = NULL;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 5. Create new membership
        DECLARE @OutputTable TABLE (UniqueId UNIQUEIDENTIFIER, Status NVARCHAR(20), CreationStatus NVARCHAR(20));
        INSERT INTO dbo.Memberships (MobileNumberId, AppDeviceId, VerificationFlowId, Status, CreationStatus)
            OUTPUT inserted.UniqueId, inserted.Status, inserted.CreationStatus INTO @OutputTable
        VALUES (@MobileNumberId, @AppDeviceId, @FlowUniqueId, 'active', @CreationStatus);

        SELECT @MembershipUniqueId = UniqueId, @Status = Status, @ResultCreationStatus = CreationStatus FROM @OutputTable;

        UPDATE dbo.OtpRecords SET IsActive = 0 WHERE UniqueId = @OtpUniqueId AND FlowUniqueId = @FlowUniqueId;

        SET @Outcome = 'created';
        -- Log attempt (success or already exists)
        INSERT INTO dbo.MembershipAttempts (MembershipId, AttemptType, Status, ErrorMessage, AttemptedAt, CreatedAt, UpdatedAt, IsDeleted)
        SELECT TOP 1 m.UniqueId, 'create', 
            CASE WHEN @Outcome = 'created' THEN 'success' ELSE 'failed' END, 
            @Outcome, GETUTCDATE(), GETUTCDATE(), GETUTCDATE(), 0
        FROM dbo.Memberships m
        WHERE m.MobileNumberId = @MobileNumberId AND m.IsDeleted = 0
        ORDER BY m.CreatedAt DESC;

        -- Remove failed attempts for all memberships of this Mobile number
        DELETE ma
        FROM dbo.MembershipAttempts ma
        INNER JOIN dbo.Memberships m ON ma.MembershipId = m.UniqueId
        WHERE m.MobileNumberId = @MobileNumberId
            AND ma.Status = 'failed'
            AND ma.IsDeleted = 0
            AND m.IsDeleted = 0;

        -- Log event (optional, similar to SP_LogEvent)
        EXEC dbo.SP_LogEvent
            @EventType = 'membership_created',
            @Severity = 'info',
            @Message = 'Membership created',
            @EntityType = 'Membership',
            @EntityId = @MembershipUniqueId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Outcome = 'error';
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log error
        EXEC dbo.SP_LogEvent
            @EventType = 'membership_creation_failed',
            @Severity = 'error',
            @Message = @ErrorMessage,
            @EntityType = 'Membership',
            @EntityId = @MembershipUniqueId;

        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END
GO