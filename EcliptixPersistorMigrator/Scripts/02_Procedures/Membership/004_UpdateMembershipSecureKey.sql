-- ============================================
-- Object: UpdateMembershipSecureKey Procedure
-- Type: Membership Procedure
-- Purpose: Updates secure key for existing membership with validation
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: Memberships table, LogMembershipAttempt procedure
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.UpdateMembershipSecureKey', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpdateMembershipSecureKey;
GO

-- Create UpdateMembershipSecureKey procedure
-- Updates secure key for existing membership with comprehensive validation
CREATE PROCEDURE dbo.UpdateMembershipSecureKey
    @MembershipUniqueId UNIQUEIDENTIFIER,
    @SecureKey VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PhoneNumberId UNIQUEIDENTIFIER;
    DECLARE @CurrentStatus NVARCHAR(20), @CurrentCreationStatus NVARCHAR(20);

    IF @SecureKey IS NULL OR DATALENGTH(@SecureKey) = 0
    BEGIN
        SELECT 0 AS Success, 'Secure key cannot be empty' AS Message, NULL AS MembershipUniqueId, NULL AS Status, NULL AS CreationStatus;
        RETURN;
    END

    SELECT @PhoneNumberId = PhoneNumberId
    FROM dbo.Memberships
    WHERE UniqueId = @MembershipUniqueId AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        -- No point in logging if we don't know PhoneNumberId
        SELECT 0 AS Success, 'Membership not found or deleted' AS Message, NULL AS MembershipUniqueId, NULL AS Status, NULL AS CreationStatus;
        RETURN;
    END

    UPDATE dbo.Memberships
    SET SecureKey = @SecureKey,
        Status = 'active',
        CreationStatus = 'secure_key_set'
    WHERE UniqueId = @MembershipUniqueId;

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC dbo.LogMembershipAttempt @PhoneNumberId, 'update_failed', 0;
        SELECT 0 AS Success, 'Failed to update membership' AS Message, NULL AS MembershipUniqueId, NULL AS Status, NULL AS CreationStatus;
        RETURN;
    END

    SELECT @CurrentStatus = Status, @CurrentCreationStatus = CreationStatus FROM dbo.Memberships WHERE UniqueId = @MembershipUniqueId;
    EXEC dbo.LogMembershipAttempt @PhoneNumberId, 'secure_key_updated', 1;

    SELECT 1 AS Success, 'Secure key updated successfully' AS Message, @MembershipUniqueId AS MembershipUniqueId, @CurrentStatus AS Status, @CurrentCreationStatus AS CreationStatus;
END;
GO

PRINT '✅ UpdateMembershipSecureKey procedure created successfully';
GO