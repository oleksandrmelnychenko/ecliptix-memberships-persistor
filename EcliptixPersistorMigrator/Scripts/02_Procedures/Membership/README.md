# Membership Procedures

This folder contains stored procedures for user membership management, authentication, and audit logging.

## Files

1. **001_LogLoginAttempt.sql** - Logs user login attempts for security monitoring
2. **002_LogMembershipAttempt.sql** - Logs membership creation attempts for analytics
3. **003_CreateMembership.sql** - Creates new membership with rate limiting protection
4. **004_UpdateMembershipSecureKey.sql** - Updates secure key for existing membership
5. **005_LoginMembership.sql** - Authenticates users with advanced lockout protection

## Procedure Overview

### Logging Procedures
- **LogLoginAttempt**: Records all login attempts with outcome and success status
- **LogMembershipAttempt**: Records all membership creation attempts for rate limiting

### Membership Management
- **CreateMembership**: Creates new membership after OTP verification
  - Rate limiting: 5 attempts per hour per phone number
  - Validates verification flow and connection ID
  - Prevents duplicate memberships

- **UpdateMembershipSecureKey**: Sets/updates the encrypted secure key
  - Validates secure key is not empty
  - Updates membership status to active
  - Sets creation status to 'secure_key_set'

### Authentication
- **LoginMembership**: Full authentication with lockout protection
  - 5 failed attempts trigger 5-minute lockout
  - Automatic lockout cleanup after expiration
  - Returns secure key on successful authentication
  - Clears failed attempts on success

## Security Features

- **Rate Limiting**: Prevents brute force attacks
- **Progressive Lockout**: Temporary account lockout after repeated failures
- **Comprehensive Logging**: All attempts are logged for security analysis
- **Secure Key Protection**: Encrypted storage and controlled access

## Business Rules

- Maximum 5 membership creation attempts per hour per phone
- Maximum 5 login attempts per 5-minute window
- 5-minute lockout period after failed login limit
- Automatic cleanup of failed attempts on successful operations