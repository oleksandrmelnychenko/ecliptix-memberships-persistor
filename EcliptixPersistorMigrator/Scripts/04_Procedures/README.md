# ⚙️ Stored Procedures

This directory contains all stored procedures organized by business domain.

## 📁 Structure

- **Core/**: Device and phone management procedures
- **Verification/**: Phone verification and OTP procedures
- **Membership/**: User membership management procedures
- **Logging/**: Audit and logging procedures

## 📋 File Naming Convention

`ProcedureName.sql` - One procedure per file for easy maintenance

## 🎯 Purpose

Each procedure handles a specific business operation with:
- Input validation
- Transaction management
- Error handling
- Audit logging
- Consistent return values

## 🔧 Standard Procedure Template

Each procedure follows the standard template with:
- Header comment with purpose and parameters
- Input validation
- Transaction handling
- Error logging
- Standardized return format