# Core Functions

This folder contains core system functions that provide fundamental data operations.

## Files

1. **001_GetPhoneNumber.sql** - Inline table-valued function to retrieve phone number details by UniqueId

## Usage

These functions are designed to be reusable across multiple procedures and provide consistent data access patterns.

### GetPhoneNumber Function

Returns phone number and region information for a given UniqueId:
- Input: `@UniqueId UNIQUEIDENTIFIER`
- Output: Table with `PhoneNumber` and `Region` columns
- Filters out deleted records automatically