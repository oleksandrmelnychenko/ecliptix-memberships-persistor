# EcliptixPersistorMigrator Deployment Guide

This guide provides step-by-step instructions for deploying the EcliptixMemberships database schema using the restructured, modular approach.

## 📋 Prerequisites

1. **SQL Server** - Version 2019 or later
2. **Database** - EcliptixMemberships database must exist
3. **Permissions** - db_owner or equivalent permissions
4. **Tools** - SQL Server Management Studio (SSMS) or Azure Data Studio

## 🚀 Deployment Options

### Option 1: Full Automated Deployment (Recommended)

```sql
USE [EcliptixMemberships];
GO

-- Deploy everything in correct order
:r Scripts/_Deploy/000_MasterDeploy.sql
```

### Option 2: Component-by-Component Deployment

```sql
USE [EcliptixMemberships];
GO

-- Step 1: Deploy Tables (Foundation)
:r Scripts/_Deploy/001_DeployTables.sql

-- Step 2: Deploy Functions (Required by procedures)
:r Scripts/_Deploy/002_DeployFunctions.sql

-- Step 3: Deploy Procedures (Business logic)
:r Scripts/_Deploy/003_DeployProcedures.sql

-- Step 4: Deploy Triggers (Automatic behaviors)
:r Scripts/_Deploy/004_DeployTriggers.sql
```

### Option 3: Individual File Deployment

For granular control, deploy individual files:

```sql
-- Core Tables
:r Scripts/01_Tables/Core/001_AppDevices.sql
:r Scripts/01_Tables/Core/002_PhoneNumbers.sql
-- ... continue with other files
```

## 📊 Post-Deployment Verification

### 1. Run Status Check
```sql
:r Scripts/_Helpers/StatusCheck.sql
```

### 2. Verify Object Counts
Expected objects after deployment:
- **Tables**: 10
- **Functions**: 3 (may show 2 due to overwrite)
- **Procedures**: 14
- **Triggers**: 9

### 3. Test Core Functionality

```sql
-- Test device registration
EXEC RegisterAppDeviceIfNotExists 
    @AppInstanceId = NEWID(),
    @DeviceId = NEWID(), 
    @DeviceType = 1;

-- Test phone number creation
EXEC EnsurePhoneNumber 
    @PhoneNumberString = '+1234567890',
    @Region = 'US',
    @AppDeviceId = NULL;
```

## 🔧 Migration from Existing Schema

If you have an existing EcliptixMemberships database:

### 1. Backup Current Database
```sql
BACKUP DATABASE [EcliptixMemberships] 
TO DISK = 'C:\Backups\EcliptixMemberships_Backup.bak';
```

### 2. Check for Existing Objects
```sql
-- Check for conflicting objects
SELECT name, type_desc 
FROM sys.objects 
WHERE name IN (
    'AppDevices', 'PhoneNumbers', 'VerificationFlows', 
    'OtpRecords', 'Memberships'
);
```

### 3. Handle Migration
The deployment scripts include DROP statements, so they will:
- Drop existing objects if they exist
- Recreate them with the new structure
- **⚠️ This will result in data loss**

For production migrations, consider:
- Data migration scripts
- Gradual rollout approach
- Blue-green deployment strategy

## 🛠 Development Workflow

### 1. Local Development
```bash
# Build and test locally
dotnet build
dotnet run -- -c status
dotnet run -- -c migrate -d  # Dry run
dotnet run -- -c migrate     # Apply migrations
```

### 2. Testing
```bash
# Run all tests after deployment
dotnet run -- -c status
:r Scripts/_Helpers/StatusCheck.sql
```

### 3. Production Deployment
1. Schedule maintenance window
2. Create database backup
3. Run deployment scripts
4. Verify functionality
5. Run cleanup if needed

## 📈 Performance Considerations

### Indexing Strategy
All tables include optimized indexes:
- Primary keys for uniqueness
- Foreign key indexes for joins
- Filtered indexes for active records
- Composite indexes for common queries

### Rate Limiting Implementation
- 30 verification flows per hour per phone
- 5 OTP attempts per flow
- 5 login attempts per 5-minute window
- Automatic cleanup of expired records

## 🔒 Security Features

### Authentication & Authorization
- Secure key encryption and storage
- Progressive lockout mechanisms
- Comprehensive audit logging

### Data Protection
- No plain text OTP storage
- Automatic expiration of sensitive data
- Soft delete pattern for data retention

## 🚨 Troubleshooting

### Common Issues

**Deployment Fails with Permission Error**
```sql
-- Ensure proper permissions
ALTER ROLE db_owner ADD MEMBER [YourUser];
```

**Foreign Key Constraint Errors**
- Ensure tables are deployed in dependency order
- Check that referenced data exists

**Function/Procedure Already Exists**
- The scripts include DROP statements
- Ensure you have permissions to drop objects

**Migration Tool Connection Issues**
- Verify connection string in appsettings.json
- Test database connectivity
- Check firewall settings

### Getting Help

1. Check the README files in each folder
2. Review the status check output
3. Examine error messages carefully
4. Verify deployment order was followed

## 📋 Maintenance Schedule

### Daily
- Monitor system performance
- Check error logs

### Weekly  
- Review security audit logs
- Monitor rate limiting effectiveness

### Monthly
```sql
-- Run cleanup script
:r Scripts/_Helpers/Cleanup.sql
```

### Quarterly
- Full database health check
- Index maintenance
- Statistics updates

## ✅ Success Criteria

Your deployment is successful when:

1. ✅ All 36 database objects created successfully
2. ✅ Status check shows all objects as active
3. ✅ Core functionality tests pass
4. ✅ No error messages in deployment log
5. ✅ Application can connect and perform basic operations

## 📞 Support

For deployment issues:
1. Check this guide first
2. Review component-specific README files
3. Examine error messages and logs
4. Create detailed issue reports with:
   - Error messages
   - Deployment steps taken
   - Environment details
   - Status check output

---

**Next Steps**: After successful deployment, refer to the operational documentation in `Scripts/README.md` for day-to-day management and maintenance procedures.
