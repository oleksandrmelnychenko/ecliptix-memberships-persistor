# 03_Functions

This folder contains user-defined functions organized by domain functionality.

## Structure

- **Core/** - Core system functions for basic operations
  - Data retrieval and transformation functions
  - Utility functions used across multiple procedures

## Function Types

- **Scalar Functions** - Return a single value
- **Table-Valued Functions** - Return a table
  - Inline Table-Valued Functions (preferred for performance)
  - Multi-Statement Table-Valued Functions

## Deployment Order

1. Tables must be created first (01_Tables)
2. Functions should be created before procedures that depend on them
3. Functions can be used by procedures, triggers, and other functions
4. Core functions first, then domain-specific functions

## Function Naming Convention

- Format: `{ActionName}.sql` or `{DomainPrefix}_{ActionName}.sql`
- Examples: `GetPhoneNumber.sql`, `ValidateOTP.sql`
- Use descriptive names that clearly indicate the function's purpose
- Avoid generic names like "Get" or "Check"