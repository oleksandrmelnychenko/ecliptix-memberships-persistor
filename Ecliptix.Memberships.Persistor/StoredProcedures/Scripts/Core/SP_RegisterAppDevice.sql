-- ============================================================================
-- SP_RegisterAppDevice - Register application device if not exists
-- ============================================================================
-- Purpose: Registers an application device, avoiding duplicates
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.SP_RegisterAppDevice
    @AppInstanceId UNIQUEIDENTIFIER,
    @DeviceId UNIQUEIDENTIFIER,
    @DeviceType INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeviceUniqueId UNIQUEIDENTIFIER;
    DECLARE @DeviceRecordId BIGINT;
    DECLARE @Status INT = 0; -- 0=Error, 1=AlreadyExists, 2=NewRegistration

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check if device already exists
        SELECT @DeviceRecordId = Id, @DeviceUniqueId = UniqueId
        FROM dbo.Devices
        WHERE DeviceId = @DeviceId
          AND IsDeleted = 0;

        -- Create if doesn't exist
        IF @DeviceRecordId IS NULL
        BEGIN
            SET @DeviceUniqueId = NEWID();

            INSERT INTO dbo.Devices (
                AppInstanceId, DeviceId, DeviceType, UniqueId,
                CreatedAt, UpdatedAt, IsDeleted
            )
            VALUES (
                @AppInstanceId, @DeviceId, @DeviceType, @DeviceUniqueId,
                GETUTCDATE(), GETUTCDATE(), 0
            );

            SET @DeviceRecordId = SCOPE_IDENTITY();
            SET @Status = 2; -- SuccessNewRegistration

            -- Log creation
            EXEC dbo.SP_LogEvent
                @EventType = 'device_registered',
                @Message = 'New application device registered',
                @EntityType = 'Device',
                @EntityId = @DeviceRecordId
        END
        ELSE
        BEGIN
            -- Update last seen if exists
            UPDATE dbo.Devices
            SET UpdatedAt = GETUTCDATE(),
                AppInstanceId = @AppInstanceId  -- Update in case app was reinstalled
            WHERE Id = @DeviceRecordId;

            SET @Status = 1; -- SuccessAlreadyExists
        END

        COMMIT TRANSACTION;

        -- Return result set
        SELECT @DeviceUniqueId AS UniqueId, @Status AS Status;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Return error status
        SELECT CAST(CAST(0 AS BINARY(16)) AS UNIQUEIDENTIFIER) AS UniqueId, 0 AS Status;

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO