# 05_Triggers

This folder contains database triggers organized by functionality.

## Structure

- **UpdatedAt/** - Triggers that automatically update the `UpdatedAt` field when records are modified
  - Ensures consistent timestamp tracking across all tables
  - Prevents recursion by checking if UpdatedAt was already updated
  - Uses `GETUTCDATE()` for consistent timezone handling

## Deployment Order

1. Tables must be created first (01_Tables)
2. Triggers can be deployed after their dependent tables exist
3. All UpdatedAt triggers follow the same pattern for consistency

## Trigger Naming Convention

- Format: `TRG_{TableName}_{TriggerType}.sql`
- Example: `TRG_AppDevices_Update.sql`
- Consistent with SQL Server trigger naming standards