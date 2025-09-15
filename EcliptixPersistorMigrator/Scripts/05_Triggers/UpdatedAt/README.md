# UpdatedAt Triggers

This folder contains triggers that automatically update the `UpdatedAt` field when records are modified.

## Pattern

All triggers follow a consistent pattern:
1. Set `SET NOCOUNT ON` for performance
2. Check `IF UPDATE(UpdatedAt) RETURN` to prevent recursion
3. Update `UpdatedAt = GETUTCDATE()` for modified records
4. Use proper JOIN with `inserted` table to identify changed records

## Files

1. **001_TRG_AppDevices_Update.sql** - Updates AppDevices.UpdatedAt
2. **002_TRG_PhoneNumbers_Update.sql** - Updates PhoneNumbers.UpdatedAt
3. **003_TRG_PhoneNumberDevices_Update.sql** - Updates PhoneNumberDevices.UpdatedAt
4. **004_TRG_VerificationFlows_Update.sql** - Updates VerificationFlows.UpdatedAt
5. **005_TRG_OtpRecords_Update.sql** - Updates OtpRecords.UpdatedAt
6. **006_TRG_FailedOtpAttempts_Update.sql** - Updates FailedOtpAttempts.UpdatedAt
7. **007_TRG_Memberships_Update.sql** - Updates Memberships.UpdatedAt
8. **008_TRG_MembershipAttempts_Update.sql** - Updates MembershipAttempts.UpdatedAt
9. **009_TRG_LoginAttempts_Update.sql** - Updates LoginAttempts.UpdatedAt

## Notes

- These triggers ensure consistent timestamp tracking across the database
- The recursion prevention is critical to avoid infinite update loops
- All timestamps use UTC for consistency