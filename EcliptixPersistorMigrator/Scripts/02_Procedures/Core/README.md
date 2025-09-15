# Core Procedures

This folder contains core system procedures that provide fundamental operations for device management, phone number operations, and security features.

## Files

1. **001_RegisterAppDeviceIfNotExists.sql** - Registers a device if it doesn't already exist
2. **002_EnsurePhoneNumber.sql** - Creates phone number if it doesn't exist and optionally associates with device
3. **003_VerifyPhoneForSecretKeyRecovery.sql** - Verifies if a phone number is eligible for secure key recovery

## Procedure Descriptions

### RegisterAppDeviceIfNotExists
- Registers a new app device or returns existing device UniqueId
- Uses locking to prevent race conditions
- Returns status: 1=Exists, 2=Created

### EnsurePhoneNumber
- Creates phone number if it doesn't exist
- Optionally associates phone number with app device
- Handles device-phone relationships with primary device logic
- Uses locking to prevent race conditions

### VerifyPhoneForSecretKeyRecovery
- Checks if a phone number is eligible for secure key recovery
- Validates membership status and secure key availability
- R1eturns detailed status information for recovery workflows