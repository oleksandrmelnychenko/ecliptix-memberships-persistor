using Ecliptix.Memberships.Persistor.Schema.Entities;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;

public interface IAppDeviceService
{
    public Task<StoredProcedureResult<DeviceRegistrationData>> RegisterAppDeviceAsync(
        Guid appInstanceId,
        Guid deviceId,
        int deviceType = 1,
        CancellationToken cancellationToken = default);
}