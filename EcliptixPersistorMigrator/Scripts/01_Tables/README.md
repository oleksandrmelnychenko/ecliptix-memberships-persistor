# 📊 Database Tables

This directory contains all database table definitions organized by business domain.

## 📁 Structure

- **Core/**: Foundational tables (AppDevices, PhoneNumbers)
- **Relationships/**: Many-to-many relationship tables
- **Verification/**: Phone verification workflow tables
- **Membership/**: User membership and account tables
- **Logging/**: Audit and logging tables

## 📋 File Naming Convention

`###_TableName.sql` - Where ### is the execution order number

## 🔗 Dependencies

Tables are numbered to ensure proper creation order based on foreign key dependencies:
1. Core tables first (no dependencies)
2. Relationship tables next
3. Business domain tables
4. Logging tables last

## ✅ Each Table File Contains

- Table definition with all columns
- Primary key constraints
- Foreign key constraints
- Check constraints
- Default constraints
- Indexes specific to the table