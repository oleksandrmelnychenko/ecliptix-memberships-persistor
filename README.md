# EcliptixPersistorMigrator

A professional enterprise-grade database migration tool built with .NET 9.0, designed for SQL Server database schema management and data seeding operations.

## Features

- **Database Migrations**: Apply versioned schema changes with validation
- **Seed Data Management**: Manage reference data with dedicated seed operations
- **Backup & Restore**: Create backups before migrations and restore when needed
- **Migration Validation**: Validate scripts before execution with detailed error reporting
- **Dry Run Mode**: Preview changes without executing them
- **Rollback Support**: Rollback to specific migration versions
- **Connection Testing**: Verify database connectivity
- **Status Reporting**: View current migration status with JSON output support
- **Transaction Safety**: All operations run within transactions for data integrity

## Quick Start

### Prerequisites

- .NET 9.0 SDK
- SQL Server database
- Valid connection string

### Installation

1. Clone the repository:
```bash
git clone https://github.com/oleksandrmelnychenko/ecliptix-db-migrator.git
cd ecliptix-db-migrator
```

2. Build the project:
```bash
dotnet build
```

3. Configure your connection string in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "EcliptixMemberships": "Server=localhost;Database=MyDatabase;Trusted_Connection=true;"
  }
}
```

## Usage

### Basic Commands

#### Test Database Connection
```bash
dotnet run -- test
```

#### Apply All Pending Migrations
```bash
dotnet run -- migrate
```

#### Check Migration Status
```bash
dotnet run -- status
```

#### List Available Migrations
```bash
dotnet run -- list
```

### Advanced Migration Operations

#### Dry Run (Preview Changes)
```bash
dotnet run -- migrate --dry-run
```

#### Migrate to Specific Version
```bash
dotnet run -- migrate --target-version V005
```

#### Force Migration (Skip Validation)
```bash
dotnet run -- migrate --force
```

#### Create Backup Before Migration
```bash
dotnet run -- migrate --create-backup
```

#### Verbose Output
```bash
dotnet run -- migrate --verbose
```

### Validation and Testing

#### Validate Migration Scripts
```bash
dotnet run -- validate
```

#### Validate Specific Version Range
```bash
dotnet run -- validate --target-version V010
```

### Backup and Restore Operations

#### Create Database Backup
```bash
dotnet run -- backup --backup-name "pre-migration-backup"
```

#### Restore from Backup
```bash
dotnet run -- restore --backup-name "pre-migration-backup"
```

### Rollback Operations

#### Rollback to Specific Version
```bash
dotnet run -- rollback --target-version V003
```

#### Rollback with Backup
```bash
dotnet run -- rollback --target-version V003 --create-backup
```

### Seed Data Management

#### Apply Seed Data
```bash
dotnet run -- seed
```

#### Apply Specific Seed Version
```bash
dotnet run -- seed --target-version S002
```

### Status and Reporting

#### Get Detailed Status (JSON Format)
```bash
dotnet run -- status --format json --verbose
```

#### Export Migration History
```bash
dotnet run -- export --output-path "./migration-report.json"
```

### Utility Commands

#### Generate New Migration Template
```bash
dotnet run -- generate --name "AddUserTable"
```

#### Mark Migration as Executed (Manual)
```bash
dotnet run -- mark --version V005 --executed
```

#### Get Migration History
```bash
dotnet run -- history --limit 10
```

#### Show Pending Migrations
```bash
dotnet run -- pending
```

#### Show Database Info
```bash
dotnet run -- info
```

#### Repair Migration History
```bash
dotnet run -- repair
```

#### Show Differences
```bash
dotnet run -- diff --target-version V008
```

## Migration File Structure

### Migration Files
- Location: `Migrations/`
- Naming: `V{version}__{description}.sql`
- Example: `V001__CreateUserTable.sql`

### Seed Files
- Location: `Migrations/Seeds/`
- Naming: `S{version}__{description}.sql`
- Example: `S001__InitialUserRoles.sql`

## Configuration

### appsettings.json
```json
{
  "ConnectionStrings": {
    "EcliptixMemberships": "your-connection-string-here"
  },
  "MigrationSettings": {
    "Schema": "dbo",
    "CommandTimeout": 30,
    "TransactionTimeout": 300,
    "BackupDirectory": "./backups",
    "ValidateBeforeExecution": true,
    "CreateBackupBeforeMigration": false
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "EcliptixPersistorMigrator": "Debug"
    }
  }
}
```

## Exit Codes

- `0`: Success
- `1`: General error
- `2`: Invalid arguments
- `3`: Database connection error
- `4`: Migration error
- `5`: Validation error

## Development

### Project Structure
```
EcliptixPersistorMigrator/
├── Application/Commands/     # Command implementations
├── Core/                    # Domain models and interfaces
├── Infrastructure/          # Database access and migration engine
├── Presentation/Cli/        # Command-line interface
├── Configuration/           # Constants and settings
└── Migrations/             # SQL migration files
```

### Build and Test
```bash
# Build project
dotnet build

# Run tests (if available)
dotnet test

# Create release build
dotnet build --configuration Release
```

### Adding New Migrations
1. Create SQL file in `Migrations/` folder
2. Follow naming convention: `V{next_version}__{description}.sql`
3. Write your SQL schema changes
4. Test with dry-run mode first

### Adding Seed Data
1. Create SQL file in `Migrations/Seeds/` folder
2. Follow naming convention: `S{next_version}__{description}.sql`
3. Write your INSERT/UPDATE statements
4. Reference data should be idempotent

## Best Practices

1. **Always test migrations** with `--dry-run` first
2. **Create backups** before production migrations
3. **Use transactions** for complex operations
4. **Validate scripts** before execution
5. **Keep migrations small** and focused
6. **Use descriptive names** for migration files
7. **Test rollback procedures** in development
8. **Monitor execution times** for performance issues

## Troubleshooting

### Common Issues

#### Connection Failures
- Verify connection string format
- Check SQL Server is running
- Confirm network connectivity
- Validate credentials and permissions

#### Migration Failures
- Check SQL syntax in migration files
- Verify target database objects exist
- Review transaction isolation levels
- Check for blocking locks

#### Permission Issues
- Ensure database user has CREATE/ALTER/DROP permissions
- Verify schema access rights
- Check backup/restore permissions if using those features

### Getting Help
```bash
# General help
dotnet run -- --help

# Command-specific help
dotnet run -- migrate --help
dotnet run -- status --help
```

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please use the project's issue tracker or contact the development team.