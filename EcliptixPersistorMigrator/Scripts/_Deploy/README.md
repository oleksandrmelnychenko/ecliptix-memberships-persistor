# 🚀 Deployment Scripts

This directory contains deployment and maintenance scripts for the database structure.

## 📁 Files

- **FullDeploy.sql**: Complete database deployment script
- **DropAll.sql**: Clean removal of all objects
- **ValidateSchema.sql**: Schema validation and verification

## 🎯 Purpose

### FullDeploy.sql
- Executes all scripts in correct dependency order
- Used for fresh database creation
- Used by migration system

### DropAll.sql
- Safely removes all objects in reverse dependency order
- Used for testing and cleanup
- Preserves data if needed

### ValidateSchema.sql
- Validates all objects exist
- Checks constraints and relationships
- Verifies permissions

## 🔄 Usage

```sql
-- Fresh deployment
:r FullDeploy.sql

-- Clean removal
:r DropAll.sql

-- Validation check
:r ValidateSchema.sql
```