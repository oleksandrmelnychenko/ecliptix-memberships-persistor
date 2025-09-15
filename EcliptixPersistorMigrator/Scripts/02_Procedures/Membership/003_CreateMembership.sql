-- ============================================
-- Object: CreateMembership Procedure
-- Type: Membership Procedure
-- Purpose: Creates new membership with rate limiting and attempt tracking
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: VerificationFlows, PhoneNumbers, Memberships, MembershipAttempts, OtpRecords, LogMembershipAttempt
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.CreateMembership', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CreateMembership;
GO

-- Create CreateMembership procedure
-- Creates new membership with comprehensive rate limiting and validation
CREATE PROCEDURE dbo.CreateMembership
    @FlowUniqueId UNIQUEIDENTIFIER,
    @ConnectionId BIGINT,
    @OtpUniqueId UNIQUEIDENTIFIER,
    @CreationStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MembershipUniqueId UNIQUEIDENTIFIER;
    DECLARE @Status NVARCHAR(20);
    DECLARE @Outcome NVARCHAR(100);

    DECLARE @PhoneNumberId UNIQUEIDENTIFIER;
    DECLARE @AppDeviceId UNIQUEIDENTIFIER;
    DECLARE @ExistingMembershipId BIGINT;
    DECLARE @ExistingCreationStatus NVARCHAR(20);

    DECLARE @FailedAttempts INT;
    DECLARE @AttemptWindowHours INT = 1;
    DECLARE @MaxAttempts INT = 5;
    DECLARE @EarliestFailedAttempt DATETIME2(7);
    DECLARE @WaitMinutes INT;

    SELECT @PhoneNumberId = pn.UniqueId
    FROM dbo.VerificationFlows vf
    JOIN dbo.PhoneNumbers pn ON vf.PhoneNumberId = pn.Id
    WHERE vf.UniqueId = @FlowUniqueId AND vf.IsDeleted = 0;

    -- Rate limiting check (5 attempts per hour)
    SELECT
        @FailedAttempts = COUNT(*),
        @EarliestFailedAttempt = MIN(Timestamp)
    FROM dbo.MembershipAttempts
    WHERE PhoneNumberId = @PhoneNumberId
      AND IsSuccess = 0
      AND Timestamp > DATEADD(hour, -@AttemptWindowHours, GETUTCDATE())
    OPTION (MAXRECURSION 100);

    IF @FailedAttempts >= @MaxAttempts
    BEGIN
        SET @WaitMinutes = DATEDIFF(minute, GETUTCDATE(), DATEADD(hour, @AttemptWindowHours, @EarliestFailedAttempt));
        SET @Outcome = CAST(CASE WHEN @WaitMinutes < 0 THEN 0 ELSE @WaitMinutes END AS NVARCHAR(100));
        EXEC dbo.LogMembershipAttempt @PhoneNumberId, @Outcome, 0;
        SELECT NULL AS MembershipUniqueId, NULL AS Status, @CreationStatus AS CreationStatus, @Outcome AS Outcome;
        RETURN;
    END

    -- Get session details
    SELECT
        @PhoneNumberId = pn.UniqueId,
        @AppDeviceId = vf.AppDeviceId
    FROM dbo.VerificationFlows vf
    JOIN dbo.PhoneNumbers pn ON vf.PhoneNumberId = pn.Id
    WHERE vf.UniqueId = @FlowUniqueId
      AND vf.ConnectionId = @ConnectionId
      AND vf.Purpose = 'registration'
      AND vf.IsDeleted = 0
      AND pn.IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        SET @Outcome = 'verification_flow_not_found';
        -- Log only if we were able to get PhoneNumberId earlier
        IF @PhoneNumberId IS NOT NULL EXEC dbo.LogMembershipAttempt @PhoneNumberId, @Outcome, 0;
        SELECT NULL AS MembershipUniqueId, NULL AS Status, NULL AS CreationStatus, @Outcome AS Outcome;
        RETURN;
    END

    -- Check for existing membership
    SELECT TOP 1
        @ExistingMembershipId = Id,
        @MembershipUniqueId = UniqueId,
        @Status = Status,
        @ExistingCreationStatus = CreationStatus
    FROM dbo.Memberships
    WHERE PhoneNumberId = @PhoneNumberId AND AppDeviceId = @AppDeviceId AND IsDeleted = 0;

    IF @ExistingMembershipId IS NOT NULL
    BEGIN
        SET @Outcome = 'membership_already_exists';
        EXEC dbo.LogMembershipAttempt @PhoneNumberId, @Outcome, 1;
        SELECT @MembershipUniqueId AS MembershipUniqueId, @Status AS Status, @ExistingCreationStatus AS CreationStatus, @Outcome AS Outcome;
        RETURN;
    END

    -- Create new membership
    DECLARE @OutputTable TABLE (UniqueId UNIQUEIDENTIFIER, Status NVARCHAR(20), CreationStatus NVARCHAR(20));

    INSERT INTO dbo.Memberships (PhoneNumberId, AppDeviceId, VerificationFlowId, Status, CreationStatus)
    OUTPUT inserted.UniqueId, inserted.Status, inserted.CreationStatus INTO @OutputTable
    VALUES (@PhoneNumberId, @AppDeviceId, @FlowUniqueId, 'active', @CreationStatus);

    SELECT @MembershipUniqueId = UniqueId, @Status = Status, @CreationStatus = CreationStatus FROM @OutputTable;

    UPDATE dbo.OtpRecords SET IsActive = 0 WHERE UniqueId = @OtpUniqueId AND FlowUniqueId = @FlowUniqueId;

    SET @Outcome = 'created';
    EXEC dbo.LogMembershipAttempt @PhoneNumberId, @Outcome, 1;

    DELETE FROM dbo.MembershipAttempts WHERE PhoneNumberId = @PhoneNumberId AND IsSuccess = 0;

    SELECT @MembershipUniqueId AS MembershipUniqueId, @Status AS Status, @CreationStatus AS CreationStatus, @Outcome AS Outcome;
END;
GO

PRINT '✅ CreateMembership procedure created successfully';
GO