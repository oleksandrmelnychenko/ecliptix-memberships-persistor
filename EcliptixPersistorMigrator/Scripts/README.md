# SQL Scripts Structure

This directory contains standalone SQL scripts extracted from the migration files for better management and development workflow.

## Directory Structure

```
Scripts/
├── Database/           # Table definitions and schema objects
│   ├── 01_Members.sql
│   ├── 02_AuthenticationContexts.sql
│   ├── 03_VerificationFlows.sql
│   └── 04_OtpCodes.sql
├── Procedures/         # Stored procedures
│   ├── CreateAuthContext.sql
│   ├── ValidateAuthContext.sql
│   └── CreateVerificationFlow.sql
├── Functions/          # User-defined functions
│   ├── GetConfigValue.sql
│   └── HashOtpCode.sql
├── Views/              # Database views
│   └── ActiveSessions.sql
├── Indexes/            # Additional indexes (not in table scripts)
│   └── Performance_Indexes.sql
└── README.md          # This file
```

## Usage

### 1. **Development Workflow**
- **Edit SQL files directly** in your favorite SQL editor
- **Test changes** against development database
- **Create migrations** when ready to deploy

### 2. **Adding New Stored Procedure**
1. Create new file in `Scripts/Procedures/YourProcedureName.sql`
2. Use the template below:

```sql
-- ================================================
-- YourProcedureName Stored Procedure
-- ================================================
-- Purpose: Description of what this procedure does
-- Author: Your Name
-- Created: YYYY-MM-DD
-- Modified: YYYY-MM-DD - Description of changes
-- ================================================

USE [EcliptixMemberships];
GO

IF OBJECT_ID('dbo.YourProcedureName', 'P') IS NOT NULL
    DROP PROCEDURE dbo.YourProcedureName;
GO

CREATE PROCEDURE dbo.YourProcedureName
    @Parameter1 DATATYPE,
    @Parameter2 DATATYPE = DEFAULT_VALUE
AS
BEGIN
    SET NOCOUNT ON;

    -- Your procedure logic here

END
GO

PRINT 'YourProcedureName stored procedure created successfully';
GO
```

3. **Create migration** to deploy the procedure:
   - Create `V015__Add_YourProcedureName.sql` in Migrations folder
   - Reference or include the procedure script

### 3. **Creating Migration from Scripts**
When you're ready to deploy changes, create a new migration file:

```sql
-- V015__Add_New_Procedure.sql
USE [EcliptixMemberships];
GO

-- Include your procedure from Scripts/Procedures/
:r Scripts/Procedures/YourProcedureName.sql

-- OR copy the content directly
-- [Your procedure content here]

PRINT 'Migration V015: Added YourProcedureName procedure';
GO
```

## Benefits of This Structure

### ✅ **Advantages**
- **Easy to edit** - Direct SQL file editing
- **Version control friendly** - Clear diffs in Git
- **IDE support** - Full SQL IntelliSense and syntax highlighting
- **Modular** - Each object in its own file
- **Searchable** - Easy to find specific procedures/tables
- **Testable** - Run scripts independently during development

### ⚠️ **Important Notes**
- **Migrations still control deployment** - These are source files only
- **Keep both in sync** - Update migration when changing scripts
- **Use for new development** - Existing migrations should not be modified
- **Test thoroughly** - Always test scripts before creating migrations

## Integration with Migration System

The migration system (`V001-V014`) remains the **source of truth** for deployment. These scripts are for:
1. **Development** - Easy editing and testing
2. **Documentation** - Clear structure and organization
3. **New features** - Starting point for new migrations

### Workflow Example:
1. **Edit** `Scripts/Procedures/CreateAuthContext.sql`
2. **Test** changes on development database
3. **Create** `V015__Update_CreateAuthContext.sql` migration
4. **Deploy** via `dotnet run -- migrate`