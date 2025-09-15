# EcliptixMemberships Database Scripts

This folder contains a well-organized, modular database schema for the EcliptixMemberships system, extracted and restructured from the original monolithic scripts.

## 📁 Folder Structure

### Core Database Objects
- **01_Tables/** - Database tables organized by domain
- **02_Procedures/** - Stored procedures organized by functionality
- **03_Functions/** - User-defined functions organized by domain
- **05_Triggers/** - Database triggers organized by type

### Deployment & Utilities
- **_Deploy/** - Deployment scripts for orchestrated schema deployment
- **_Helpers/** - Utility scripts for maintenance and monitoring

## 🚀 Quick Start

To deploy the complete database schema:

```sql
USE [EcliptixMemberships];
:r _Deploy/000_MasterDeploy.sql
```

## 📊 Schema Overview

### Tables (10 total)
- **Core**: AppDevices, PhoneNumbers
- **Relationships**: PhoneNumberDevices
- **Verification**: VerificationFlows, OtpRecords, FailedOtpAttempts
- **Membership**: Memberships, MembershipAttempts
- **Logging**: LoginAttempts, EventLog

### Functions (3 total)
- **GetPhoneNumber** - Phone number retrieval utilities
- **GetFullFlowState** - Comprehensive verification flow state

### Procedures (14 total)
- **Core (3)**: Device registration, phone management, recovery verification
- **Verification (6)**: OTP workflow management with rate limiting
- **Membership (5)**: User authentication and membership lifecycle

### Triggers (9 total)
- **UpdatedAt triggers** - Automatic timestamp management for all tables

## 🔒 Security Features

- **Rate Limiting**: 30 flows/hour, 5 OTP attempts/flow, 5 login attempts/5min
- **Progressive Lockout**: Temporary account lockout after repeated failures
- **Comprehensive Logging**: All attempts logged for security analysis
- **Secure Key Protection**: Encrypted storage and controlled access

## 📋 Business Rules

- Maximum 30 verification flows per hour per phone number
- Maximum 5 OTP attempts per verification flow
- 30-second cooldown between OTP sends
- **30-second OTP timeout** - Individual OTPs expire after 30 seconds
- **1-minute verification session timeout** - Sessions expire after 1 minute
- 24-hour verified flow validity
- 5-minute lockout period after failed login limit

## 🛠 Maintenance

Regular maintenance scripts are available in `_Helpers/`:
- **StatusCheck.sql** - Health monitoring and statistics
- **Cleanup.sql** - Automated cleanup of expired records

## 📖 Documentation

Each folder contains detailed README files explaining:
- Purpose and functionality of components
- Dependencies and deployment order
- Usage examples and best practices
- Security considerations and business rules

## 🏗 Architecture Principles

- **Modular Design**: Each component is self-contained with clear dependencies
- **Security First**: Rate limiting, logging, and secure key management built-in
- **Performance Optimized**: Proper indexing and query optimization
- **Maintainable**: Clear naming conventions and comprehensive documentation
- **Scalable**: Designed to handle production workloads efficiently

For detailed information about specific components, refer to the README files in each subdirectory.
