# 🚀 EcliptixPersistorMigrator

A comprehensive database migration solution for Ecliptix that replaces problematic MasterDeployment.sql with a professional CLI tool.

## 🎯 Problem Solved
- ❌ **Before**: "Incorrect syntax near ';'" at line 489 in MasterDeployment.sql
- ✅ **After**: Clean, versioned migrations with smart schema detection

## 🆘 Quick Start
**Having issues with existing database?** → See [COMPREHENSIVE_SOLUTION.md](COMPREHENSIVE_SOLUTION.md) for detailed resolution steps.

## Overview

This console application provides a clean, versioned approach to database migrations, replacing the complex MasterDeployment.sql approach with individual, maintainable migration scripts.

## Features

- ✅ **Versioned Migrations**: Sequential V001, V002, etc. approach
- ✅ **Seed Data Management**: Separate seed scripts for initial data
- ✅ **Status Tracking**: See what migrations have been applied
- ✅ **Dry Run Mode**: Preview changes without executing them
- ✅ **Transaction Safety**: Each migration runs in its own transaction
- ✅ **Command Line Interface**: Easy to use in CI/CD pipelines
- ⚠️ **Rollback Support**: Planned for future release

## Commands

### Migrate
Apply pending migrations to the database:
```bash
# Apply all pending migrations
dotnet run -- -c migrate

# Dry run (preview what would be executed)
dotnet run -- -c migrate -d

# With custom connection string
dotnet run -- -c migrate -s "Server=myserver;Database=EcliptixMemberships;..."
```

### Status
Check migration status:
```bash
# Show current migration status
dotnet run -- -c status
```

### Seed
Apply seed data:
```bash
# Apply seed data
dotnet run -- -c seed

# Dry run seed data
dotnet run -- -c seed -d
```

### Rollback
Rollback to a specific version (placeholder):
```bash
# Rollback to specific version
dotnet run -- -c rollback -v V001
```

## Migration Structure

```
Migrations/
├── V001__Baseline_Configuration.sql    # Core configuration tables & functions
├── V002__Core_Domain_Tables.sql        # Main business tables
└── Seeds/
    └── S001__Default_Configuration.sql # Initial configuration data
```

## Configuration

Edit `appsettings.json` to configure your database connection:

```json
{
  "ConnectionStrings": {
    "EcliptixMemberships": "Server=localhost;Database=EcliptixMemberships;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;MultipleActiveResultSets=true"
  }
}
```

## Usage Examples

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

### CI/CD Pipeline
```yaml
# Example Azure DevOps task
- task: DotNetCoreCLI@2
  displayName: 'Apply Database Migrations'
  inputs:
    command: 'run'
    projects: '**/EcliptixPersistorMigrator.csproj'
    arguments: '-- -c migrate'
```

## Migration Best Practices

1. **Never modify existing migrations** - Create new ones instead
2. **Use descriptive names** - V003__Add_User_Email_Column.sql
3. **Test rollbacks** - Always plan for rollback scenarios
4. **Keep migrations small** - One logical change per migration
5. **Use transactions** - Each migration should be atomic

## Advantages over MasterDeployment.sql

| Feature | MasterDeployment.sql | EcliptixPersistorMigrator |
|---------|---------------------|---------------------------|
| Version Control | ❌ Single file | ✅ Individual files |
| Rollback Support | ❌ Manual | ✅ Planned/Automated |
| Change Tracking | ❌ None | ✅ Full history |
| Team Development | ❌ Merge conflicts | ✅ No conflicts |
| Error Recovery | ❌ Start over | ✅ Resume from failure |
| Syntax Errors | ❌ Complex GOTO issues | ✅ Clean, simple SQL |

## Development

### Building
```bash
dotnet build
```

### Testing Locally
```bash
# Build and run
dotnet build && dotnet run -- -c status
```

## Migration History

The tool tracks migrations in the `dbo.SchemaVersions` table and seed data in the `dbo.SeedVersions` table.

## Troubleshooting

### Connection Issues
- Verify connection string in appsettings.json
- Ensure SQL Server is running and accessible
- Check firewall settings

### Migration Failures
- Use `--verbose` flag for detailed logging
- Check the error message for SQL syntax issues
- Verify database permissions

### Script Not Found
- Ensure SQL files are marked as Embedded Resources
- Check file naming convention (V###__Description.sql)

## Support

For issues or questions:
1. Check the logs with `--verbose` flag
2. Verify database connectivity
3. Check migration file syntax
4. Review the troubleshooting section above

## Future Enhancements

- [ ] Rollback implementation
- [ ] Migration validation
- [ ] Backup before migration
- [ ] Custom variable support
- [ ] Environment-specific configurations