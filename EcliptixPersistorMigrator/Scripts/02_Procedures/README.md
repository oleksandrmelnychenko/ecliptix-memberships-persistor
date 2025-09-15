# 02_Procedures

This folder contains stored procedures organized by domain functionality.

## Structure

- **Core/** - Core system procedures for basic operations
  - Device registration and management
  - Phone number operations
  - Security key recovery verification

- **Verification/** - Phone verification workflow procedures
  - OTP generation and validation
  - Verification flow management
  - Rate limiting and security controls

- **Membership/** - User membership management procedures
  - Membership creation and lifecycle
  - Secure key management
  - Account status operations

## Deployment Order

1. Tables must be created first (01_Tables)
2. Functions should be created before procedures that depend on them (03_Functions)
3. Procedures can reference other procedures created in previous scripts
4. Follow the numbering sequence: Core → Verification → Membership

## Procedure Naming Convention

- Format: `{DomainPrefix}_{ActionName}.sql`
- Examples: `RegisterAppDeviceIfNotExists.sql`, `InitiateVerificationFlow.sql`
- Use descriptive names that clearly indicate the procedure's purpose