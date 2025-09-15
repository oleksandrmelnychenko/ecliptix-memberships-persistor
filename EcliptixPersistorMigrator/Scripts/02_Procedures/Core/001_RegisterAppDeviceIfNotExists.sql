-- ============================================
-- Object: RegisterAppDeviceIfNotExists Procedure
-- Type: Core Procedure
-- Purpose: Registers a device if it doesn't already exist, prevents race conditions
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: AppDevices table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.RegisterAppDeviceIfNotExists', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RegisterAppDeviceIfNotExists;
GO

-- Create RegisterAppDeviceIfNotExists procedure
-- Registers a device if it doesn't exist, using locking to prevent race conditions
CREATE PROCEDURE dbo.RegisterAppDeviceIfNotExists
    @AppInstanceId UNIQUEIDENTIFIER,
    @DeviceId UNIQUEIDENTIFIER,
    @DeviceType INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeviceUniqueId UNIQUEIDENTIFIER;
    DECLARE @Status INT;

    -- Use locking to prevent race conditions
    SELECT @DeviceUniqueId = UniqueId
    FROM dbo.AppDevices WITH (UPDLOCK, HOLDLOCK)
    WHERE DeviceId = @DeviceId AND IsDeleted = 0;

    IF @DeviceUniqueId IS NOT NULL
    BEGIN
        -- Device exists: Status = 1
        SET @Status = 1;
        SELECT @DeviceUniqueId AS UniqueId, @Status AS Status;
        RETURN;
    END
    ELSE
    BEGIN
        -- Device doesn't exist, try to insert
        INSERT INTO dbo.AppDevices (AppInstanceId, DeviceId, DeviceType)
        VALUES (@AppInstanceId, @DeviceId, @DeviceType);

        -- Get the newly created UniqueId
        SELECT @DeviceUniqueId = UniqueId FROM dbo.AppDevices WHERE DeviceId = @DeviceId;

        -- Device created: Status = 2
        SET @Status = 2;
        SELECT @DeviceUniqueId AS UniqueId, @Status AS Status;
        RETURN;
    END
END;
GO

PRINT '✅ RegisterAppDeviceIfNotExists procedure created successfully';
GO