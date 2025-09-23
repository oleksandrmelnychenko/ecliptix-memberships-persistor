using System.Data;
using Ecliptix.Memberships.Persistor.StoredProcedures.Interfaces;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models;
using Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Services;

public class AppDeviceService
{
    private readonly IStoredProcedureExecutor _executor;
    private readonly ILogger<AppDeviceService> _logger;

    public AppDeviceService(IStoredProcedureExecutor executor, ILogger<AppDeviceService> logger)
    {
        _executor = executor;
        _logger = logger;
    }
    
    public async Task<StoredProcedureResult<DeviceRegistrationData>> RegisterAppDeviceAsync(
        Guid appInstanceId,
        Guid deviceId,
        int deviceType = 1,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Registering app device: {DeviceId}", deviceId);

        SqlParameter[] parameters =
        [
            SqlParameterHelper.In("@AppInstanceId", appInstanceId),
            SqlParameterHelper.In("@DeviceId", deviceId),
            SqlParameterHelper.In("@DeviceType", deviceType),
            SqlParameterHelper.Out("@DeviceUniqueId", SqlDbType.UniqueIdentifier),
            SqlParameterHelper.Out("@DeviceRecordId", SqlDbType.BigInt),
            SqlParameterHelper.Out("@IsNewlyCreated", SqlDbType.Bit)
        ];

        return await _executor.ExecuteWithOutputAsync(
            "dbo.SP_RegisterAppDevice",
            parameters,
            outputParams => new DeviceRegistrationData(
                DeviceRecordId: (long)outputParams[4].Value,
                DeviceUniqueId: (Guid)outputParams[3].Value,
                IsNewlyCreated: (bool)outputParams[5].Value
            ),
            cancellationToken);
    }
}