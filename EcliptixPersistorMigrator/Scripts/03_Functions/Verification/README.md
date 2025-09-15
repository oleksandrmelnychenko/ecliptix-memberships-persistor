# Verification Functions

This folder contains functions specific to phone verification workflows.

## Files

1. **001_GetFullFlowState.sql** - Comprehensive verification flow state retrieval
2. **002_GetPhoneNumber.sql** - Enhanced phone number retrieval (includes UniqueId)

## Function Overview

### GetFullFlowState
- Returns complete verification flow state with active OTP
- Joins VerificationFlows, PhoneNumbers, and OtpRecords
- Used as single source of truth for flow state
- Filters active, non-expired OTPs automatically

### GetPhoneNumber (Verification Enhanced)
- Enhanced version of core GetPhoneNumber function
- Includes UniqueId in the output for verification workflows
- Maintains same filtering logic (active, non-deleted records)

## Usage Patterns

These functions are designed for use within verification procedures to:
- Provide consistent data access patterns
- Ensure proper filtering of deleted/expired records
- Reduce code duplication across procedures
- Maintain single source of truth for complex joins