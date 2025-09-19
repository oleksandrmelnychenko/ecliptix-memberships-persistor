# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ecliptix.Memberships.Persistor is a .NET 9.0 CLI database migration tool that replaces problematic MasterDeployment.sql scripts with versioned, transactional migrations. The tool provides clean migration management for the Ecliptix Memberships database with smart schema detection and upgrade capabilities.

## Commands

### Build and Run
```bash
# Build the project
dotnet build

# Apply all pending migrations
dotnet run -- -c migrate

# Preview migrations without executing (dry run)
dotnet run -- -c migrate -d

# Check migration status
dotnet run -- -c status

# Apply seed data
dotnet run -- -c seed

# Rollback to specific version (placeholder implementation)
dotnet run -- -c rollback -v V001

# With custom connection string
dotnet run -- -c migrate -s "Server=myserver;Database=EcliptixMemberships;..."

# Enable verbose logging
dotnet run -- -c migrate --verbose
```

### Development Workflow
```bash
# Check current status
dotnet run -- -c status

# Preview pending migrations
dotnet run -- -c migrate -d

# Apply migrations
dotnet run -- -c migrate

# Apply seed data
dotnet run -- -c seed
```

## Architecture

### Core Components

- **Program.cs**: Main CLI entry point using CommandLineParser
- **MigrationRunner class**: Core migration logic using DbUp framework
- **Migration Tracking**: Uses `dbo.SchemaVersions` table for migrations, `dbo.SeedVersions` for seed data

### Migration System

- **Versioned Migrations**: Sequential V001, V002, etc. pattern in `Migrations/` folder
- **Seed Data**: Separate S001, S002, etc. pattern in `Migrations/Seeds/` folder
- **Embedded Resources**: SQL files are embedded in assembly via .csproj configuration
- **Transaction Safety**: Each migration runs in its own transaction
- **Smart Schema Detection**: V008+ includes logic to detect existing vs new schema

### Key Migration Files

- **V001-V007**: Initial baseline migrations (may have issues with existing databases)
- **V008**: Schema detection and conditional migration logic
- **V009**: Core functions and procedures
- **V010**: Upgrade path from old schema to new schema
- **V011**: Rollback safety features
- **V012-V013**: Clean schema migration and procedures

## Configuration

Connection string is configured in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "EcliptixMemberships": "Data Source=server;Initial Catalog=EcliptixMemberships;..."
  }
}
```

## Schema Migration Strategy

The tool handles two scenarios:
1. **Fresh Installation**: Clean database gets full new schema
2. **Upgrade Path**: Existing database with old schema (PhoneNumbers, OtpRecords) gets migrated to new schema (Members, OtpCodes)

The migration system uses conditional logic to detect existing schema and apply appropriate transformation paths.

## Important Notes

- **Never modify existing migrations** - create new ones instead
- **SQL files must be marked as Embedded Resources** in the .csproj file
- **Migration naming convention**: V###__Description.sql (exactly 3 digits)
- **Seed naming convention**: S###__Description.sql
- **Each migration is atomic** - wrapped in transaction with rollback on failure
- **DbUp framework** handles execution tracking and prevents re-running completed migrations

## Testing

No specific test framework is configured. Test migrations using:
- Dry run mode (`-d` flag) to preview changes
- Status command to verify applied migrations
- Verbose logging (`--verbose`) for detailed execution info