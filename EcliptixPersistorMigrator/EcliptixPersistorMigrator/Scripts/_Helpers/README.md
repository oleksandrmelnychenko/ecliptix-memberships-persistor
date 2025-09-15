# _Helpers Scripts  

This folder contains utility scripts for database maintenance and monitoring.

## Files

- **Cleanup.sql** - Removes old/expired records safely
- **StatusCheck.sql** - Checks database health and statistics
- **PerformanceMonitoring.sql** - Monitors query performance and indexes

## Usage

These scripts are for maintenance and should be run as needed:

```sql
-- Check database status
:r StatusCheck.sql

-- Clean up old records
:r Cleanup.sql

-- Monitor performance
:r PerformanceMonitoring.sql
```

## Notes

- All scripts are read-only except Cleanup.sql
- Run during maintenance windows for best results
- Review output for any issues requiring attention
