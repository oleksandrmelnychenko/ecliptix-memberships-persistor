# _Deploy Scripts

This folder contains deployment scripts for orchestrating database schema deployment in the correct order.

## Deployment Order

The correct deployment order is critical due to dependencies:

1. **Tables** - Foundation layer, no dependencies
2. **Functions** - Required by procedures  
3. **Procedures** - Can depend on functions and tables
4. **Triggers** - Must be created after their target tables exist

## Files

- **000_MasterDeploy.sql** - Master deployment script
- **001_DeployTables.sql** - Deploys all tables
- **002_DeployFunctions.sql** - Deploys all functions
- **003_DeployProcedures.sql** - Deploys all procedures
- **004_DeployTriggers.sql** - Deploys all triggers

## Usage

Run the master deployment script for full deployment:
```sql
:r 000_MasterDeploy.sql
```
