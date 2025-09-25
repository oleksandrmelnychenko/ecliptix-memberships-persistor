# Stored Procedures Module

A comprehensive stored procedures management system for the Ecliptix database with organized scripts, service layer, and testing capabilities.

## 📁 Folder Structure

```
StoredProcedures/
├── Scripts/                  # SQL stored procedure scripts
│   ├── Core/                 # Basic operations (Mobile numbers, devices)
│   ├── Verification/         # OTP and verification logic
│   ├── Membership/           # User membership operations
│   ├── Authentication/       # Login and auth procedures
│   ├── Utilities/           # Helper procedures (logging, etc.)
│   ├── _Deploy/             # Deployment scripts
│   └── _Testing/            # Test scripts
├── Services/                # C# service layer
├── Models/                  # Data transfer objects
└── Interfaces/              # Service contracts
```
## Create and push migration

```bash
dotnet ef migrations add {NameOfMigration}
```

```bash
dotnet ef database update
```


## 🚀 Usage

### 1. Deploy Stored Procedures

```bash
# Deploy all procedures to database
sqlcmd -S server -d EcliptixMemberships -i "Scripts/_Deploy/DeployAllProcedures.sql"
```

### 2. Test Procedures

```bash
# Run verification flow tests
sqlcmd -S server -d EcliptixMemberships -i "Scripts/_Testing/TestVerificationFlow.sql"
```

### 3. Use in C# Code

```csharp
// Dependency injection setup
services.AddScoped<IStoredProcedureExecutor, StoredProcedureExecutor>();
services.AddScoped<IVerificationService, VerificationService>();

// Usage in controllers/services
public class VerificationController : ControllerBase
{
    private readonly IVerificationService _verificationService;

    public async Task<IActionResult> StartVerification(string MobileNumber, string region)
    {
        var result = await _verificationService.InitiateVerificationFlowAsync(
            MobileNumber, region, deviceId);

        if (result.IsSuccess)
            return Ok(result.Data);
        else
            return BadRequest(result.ErrorMessage);
    }
}
```

## 📋 Available Stored Procedures

### Core Procedures
- **SP_EnsureMobileNumber** - Get or create Mobile number record
- **SP_RegisterAppDevice** - Register application device

### Verification Procedures
- **SP_InitiateVerificationFlow** - Start Mobile verification process
- **SP_GenerateOtpCode** - Generate OTP code for verification
- **SP_VerifyOtpCode** - Verify submitted OTP code

### Utility Procedures
- **SP_LogEvent** - System event logging

## 🔧 Service Layer

### IVerificationService
- `EnsureMobileNumberAsync()` - Mobile number management
- `RegisterAppDeviceAsync()` - Device registration
- `InitiateVerificationFlowAsync()` - Start verification
- `GenerateOtpCodeAsync()` - OTP generation
- `VerifyOtpCodeAsync()` - OTP verification

### IStoredProcedureExecutor
- `ExecuteAsync<T>()` - Execute with data reader
- `ExecuteWithOutputAsync<T>()` - Execute with output parameters
- `ExecuteNonQueryAsync()` - Execute without return data

## 📊 Error Handling

All procedures return structured results:

```csharp
public class StoredProcedureResult<T>
{
    public bool IsSuccess { get; set; }
    public string Outcome { get; set; }
    public string? ErrorMessage { get; set; }
    public T? Data { get; set; }
    public DateTime ExecutedAt { get; set; }
}
```

Common outcomes:
- `success` - Operation completed successfully
- `rate_limit_exceeded` - Too many attempts
- `flow_expired` - Verification flow expired
- `invalid_code` - OTP code incorrect
- `max_attempts_exceeded` - Too many verification attempts

## 🔐 Security Features

- **Rate Limiting**: 30 flows per hour per Mobile, 10 per device
- **OTP Expiry**: Configurable expiration (default 5 minutes)
- **Attempt Limiting**: Max 3 verification attempts per OTP
- **Audit Logging**: All operations logged to EventLogs table
- **IP Tracking**: Failed attempts tracked with IP/User Agent

## 🧪 Testing

The module includes comprehensive testing:

1. **Unit Testing**: Each procedure tested individually
2. **Integration Testing**: Complete verification flow
3. **Performance Testing**: Rate limiting and concurrent access
4. **Security Testing**: Invalid inputs and edge cases

Run tests with:
```sql
EXEC [test script] -- See Scripts/_Testing/ folder
```

## 📈 Performance Considerations

- **Connection Pooling**: Reuses database connections
- **Async Operations**: All service methods are async
- **Output Parameters**: Minimizes data transfer
- **Indexed Lookups**: All queries use proper indexes
- **Transaction Safety**: Each operation is transactional

## 🔄 Migration Integration

Stored procedures are version-controlled and deployed via:

1. **EF Core Migrations**: Include procedure updates
2. **DbUp Scripts**: Deploy via existing migration system
3. **Version Control**: SQL scripts tracked in git

## 🌐 PostgreSQL Compatibility

The service layer is designed for easy PostgreSQL migration:

- Abstract interfaces separate from SQL Server specifics
- Parameter mapping easily adaptable
- Connection string configuration supports multiple providers
- Stored procedures can be converted to PostgreSQL functions