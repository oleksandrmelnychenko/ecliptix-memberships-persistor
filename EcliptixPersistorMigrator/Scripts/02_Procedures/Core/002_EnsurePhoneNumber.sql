-- ============================================
-- Object: EnsurePhoneNumber Procedure
-- Type: Core Procedure
-- Purpose: Creates phone number if it doesn't exist and optionally associates with device
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: PhoneNumbers, AppDevices, PhoneNumberDevices tables
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.EnsurePhoneNumber', 'P') IS NOT NULL
    DROP PROCEDURE dbo.EnsurePhoneNumber;
GO

-- Create EnsurePhoneNumber procedure
-- Creates phone number if it doesn't exist and optionally associates with device
CREATE PROCEDURE dbo.EnsurePhoneNumber
    @PhoneNumberString NVARCHAR(18),
    @Region NVARCHAR(2),
    @AppDeviceId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PhoneUniqueId UNIQUEIDENTIFIER;
    DECLARE @Outcome NVARCHAR(50);
    DECLARE @Success BIT;
    DECLARE @Message NVARCHAR(255);

    -- Use locking to prevent race conditions when creating/finding phone number
    SELECT @PhoneUniqueId = UniqueId
    FROM dbo.PhoneNumbers WITH (UPDLOCK, HOLDLOCK)
    WHERE PhoneNumber = @PhoneNumberString
      AND (Region = @Region OR (Region IS NULL AND @Region IS NULL))
      AND IsDeleted = 0;

    IF @PhoneUniqueId IS NOT NULL
    BEGIN
        -- Phone number exists
        SET @Outcome = 'exists';
        SET @Success = 1;
        SET @Message = 'Phone number already exists.';

        IF @AppDeviceId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.AppDevices WHERE UniqueId = @AppDeviceId AND IsDeleted = 0)
            BEGIN
                SELECT @PhoneUniqueId AS UniqueId, 'existing_but_invalid_app_device' AS Outcome, 0 AS Success, 'Phone exists, but provided AppDeviceId is invalid' AS Message;
                RETURN;
            END

            -- Emulate ON CONFLICT DO UPDATE for the relationship
            IF EXISTS (SELECT 1 FROM dbo.PhoneNumberDevices WHERE PhoneNumberId = @PhoneUniqueId AND AppDeviceId = @AppDeviceId)
            BEGIN
                -- If relationship exists, update it if it was deleted
                UPDATE dbo.PhoneNumberDevices
                SET IsDeleted = 0, UpdatedAt = GETUTCDATE()
                WHERE PhoneNumberId = @PhoneUniqueId AND AppDeviceId = @AppDeviceId AND IsDeleted = 1;
            END
            ELSE
            BEGIN
                -- If relationship doesn't exist, create it
                INSERT INTO dbo.PhoneNumberDevices (PhoneNumberId, AppDeviceId, IsPrimary)
                VALUES (@PhoneUniqueId, @AppDeviceId, CASE WHEN EXISTS (SELECT 1 FROM dbo.PhoneNumberDevices WHERE PhoneNumberId = @PhoneUniqueId AND IsDeleted = 0) THEN 0 ELSE 1 END);
            END
            SET @Outcome = 'associated';
            SET @Message = 'Existing phone number associated with device.';
        END

        SELECT @PhoneUniqueId AS UniqueId, @Outcome AS Outcome, @Success AS Success, @Message AS Message;
    END
    ELSE
    BEGIN
        -- Phone number doesn't exist, create new one
        DECLARE @OutputTable TABLE (UniqueId UNIQUEIDENTIFIER);

        INSERT INTO dbo.PhoneNumbers (PhoneNumber, Region)
        OUTPUT inserted.UniqueId INTO @OutputTable
        VALUES (@PhoneNumberString, @Region);

        SELECT @PhoneUniqueId = UniqueId FROM @OutputTable;

        SET @Outcome = 'created';
        SET @Success = 1;
        SET @Message = 'Phone number created successfully.';

        IF @AppDeviceId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.AppDevices WHERE UniqueId = @AppDeviceId AND IsDeleted = 0)
            BEGIN
                SELECT @PhoneUniqueId AS UniqueId, 'created_but_invalid_app_device' AS Outcome, 0 AS Success, 'Phone created, but invalid AppDeviceId provided' AS Message;
                RETURN;
            END

            -- Since the phone number is new, the device will always be primary
            INSERT INTO dbo.PhoneNumberDevices (PhoneNumberId, AppDeviceId, IsPrimary)
            VALUES (@PhoneUniqueId, @AppDeviceId, 1);

            SET @Outcome = 'created_and_associated';
            SET @Message = 'Phone number created and associated with device.';
        END

        SELECT @PhoneUniqueId AS UniqueId, @Outcome AS Outcome, @Success AS Success, @Message AS Message;
    END
END;
GO

PRINT '✅ EnsurePhoneNumber procedure created successfully';
GO