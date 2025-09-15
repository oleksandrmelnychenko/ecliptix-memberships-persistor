# Verification Procedures

This folder contains stored procedures for phone verification workflow management.

## Files

1. **001_InitiateVerificationFlow.sql** - Main entry point for verification flow creation
2. **002_RequestResendOtp.sql** - Handles OTP resend requests with business rule validation
3. **003_InsertOtpRecord.sql** - Creates new OTP records with counter management
4. **004_UpdateOtpStatus.sql** - Updates OTP status and triggers flow transitions
5. **005_UpdateVerificationFlowStatus.sql** - Updates verification flow status
6. **006_ExpireAssociatedOtp.sql** - Expires all pending OTPs for a flow

## Procedure Overview

### InitiateVerificationFlow
- Single entry point for starting verification
- Handles rate limiting (30 flows per hour)
- Race-condition proof with unique constraints
- Returns existing verified flows if still valid

### RequestResendOtp
- Validates all business rules for OTP resend
- Enforces 30-second cooldown between sends
- Maximum 5 OTP attempts per flow
- Session expiration checks

### InsertOtpRecord
- Creates new OTP with proper hashing
- Increments flow OTP counter
- Validates flow state before creation

### UpdateOtpStatus
- Transitions OTP through lifecycle states
- Records failed attempts in audit table
- Updates flow status when OTP is verified

## Business Rules

- Maximum 30 verification flows per hour per phone number
- Maximum 5 OTP attempts per verification flow
- 30-second cooldown between OTP sends
- **30-second OTP timeout** - OTP expires after 30 seconds
- **1-minute verification session timeout** - Session expires after 1 minute
- 24-hour verified flow validity