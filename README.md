# Ecliptix.Memberships.Persistor

A professional enterprise-grade database migration tool built with .NET 9.0, designed for SQL Server database schema management operations for the Ecliptix Memberships system.

## Features

- **Database Migrations**: Apply versioned schema changes with validation
- **Migration Status**: View current migration status with detailed reporting
- **Connection Testing**: Verify database connectivity
- **Dry Run Mode**: Preview changes without executing them
- **Transaction Safety**: All operations run within transactions for data integrity

## Quick Start

### Prerequisites

- .NET 9.0 SDK
- SQL Server database
- Valid connection string

### Installation

1. Clone the repository:
```bash
git clone https://github.com/oleksandrmelnychenko/ecliptix-memberships-persistor.git
cd ecliptix-memberships-persistor
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

### Available Commands

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

### Migration Options

#### Dry Run (Preview Changes)
```bash
dotnet run -- migrate --dryrun
```

#### Migrate to Specific Version
```bash
dotnet run -- migrate --target V005
```

#### Force Migration (Skip Validation)
```bash
dotnet run -- migrate --force
```

#### Create Backup Before Migration
```bash
dotnet run -- migrate --backup
```

#### Verbose Output
```bash
dotnet run -- migrate --verbose
```

### Status Options

#### Get Status in JSON Format
```bash
dotnet run -- status --json
```

#### Verbose Status Output
```bash
dotnet run -- status --verbose
```

### Connection String Override
```bash
dotnet run -- test --connectionstring "Server=myserver;Database=mydb;..."
dotnet run -- migrate --connectionstring "Server=myserver;Database=mydb;..."
dotnet run -- status --connectionstring "Server=myserver;Database=mydb;..."
```

## Migration File Structure

### Migration Files
- Location: `Migrations/` (embedded resources)
- Naming: `V{version}__{description}.sql`
- Example: `V001__CreateUserTable.sql`

## Configuration

### appsettings.json
```json
{
  "ConnectionStrings": {
    "EcliptixMemberships": "your-connection-string-here"
  },
  "MigrationSettings": {
    "JournalTableName": "SchemaVersions",
    "JournalSchema": "dbo",
    "CommandTimeout": 30,
    "TransactionPerScript": true,
    "CreateSchemaVersionsTable": true
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
Ecliptix.Memberships.Persistor/
├── Schema/Entities/         # Entity Framework entity models
├── Schema/Configurations/   # EF Core fluent API configurations
├── StoredProcedures/       # Stored procedure services and scripts
├── Configuration/          # Application settings and constants
├── Migrations/            # EF Core migrations
└── Program.cs             # Main entry point with Serilog logging
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
1. Create SQL file in `Migrations/` folder as embedded resource
2. Follow naming convention: `V{next_version}__{description}.sql`
3. Write your SQL schema changes
4. Mark file as "Embedded Resource" in project settings
5. Test with dry-run mode first

## Best Practices

1. **Always test migrations** with `--dryrun` first
2. **Use transactions** for complex operations
3. **Keep migrations small** and focused
4. **Use descriptive names** for migration files
5. **Monitor execution times** for performance issues

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
dotnet run -- test --help
```

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please use the project's issue tracker or contact the development team.