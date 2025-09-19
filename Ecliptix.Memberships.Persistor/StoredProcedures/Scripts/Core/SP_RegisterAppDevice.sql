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
    @DeviceType INT = 1,
    @DeviceUniqueId UNIQUEIDENTIFIER OUTPUT,
    @DeviceRecordId BIGINT OUTPUT,
    @IsNewlyCreated BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsNewlyCreated = 0;

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
            SET @IsNewlyCreated = 1;

            -- Log creation
            EXEC dbo.SP_LogEvent
                @EventType = 'device_registered',
                @Message = 'New application device registered',
                @EntityType = 'Device',
                @EntityId = @DeviceRecordId;
        END
        ELSE
        BEGIN
            -- Update last seen if exists
            UPDATE dbo.Devices
            SET UpdatedAt = GETUTCDATE(),
                AppInstanceId = @AppInstanceId  -- Update in case app was reinstalled
            WHERE Id = @DeviceRecordId;
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO