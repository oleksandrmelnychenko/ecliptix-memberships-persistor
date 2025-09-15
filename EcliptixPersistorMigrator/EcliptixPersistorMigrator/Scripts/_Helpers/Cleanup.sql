-- ============================================
-- Database Cleanup Script
-- Purpose: Safely removes old/expired records for maintenance
-- Author: Oleksandr Melnychenko  
-- Created: 2025-09-15
-- Dependencies: All database tables
-- ============================================

USE [EcliptixMemberships];
GO

PRINT '🧹 EcliptixMemberships Database Cleanup';
PRINT 'Started: ' + CONVERT(NVARCHAR(30), GETUTCDATE(), 127);
PRINT '================================================';
GO

DECLARE @CleanupDate DATETIME2(7) = DATEADD(day, -30, GETUTCDATE()); -- 30 days old
DECLARE @RowsAffected INT;

BEGIN TRANSACTION CleanupTransaction;
GO

BEGIN TRY
    -- Clean up expired verification flows (older than 30 days)
    PRINT '';
    PRINT '🗂️  Cleaning up expired verification flows...';
    
    UPDATE VerificationFlows 
    SET IsDeleted = 1 
    WHERE Status IN ('expired', 'failed') 
        AND CreatedAt < @CleanupDate 
        AND IsDeleted = 0;
    
    SET @RowsAffected = @@ROWCOUNT;
    PRINT 'Marked ' + CAST(@RowsAffected AS NVARCHAR(10)) + ' expired verification flows for deletion';
    
    -- Clean up expired OTP records (older than 30 days)
    PRINT '';
    PRINT '🔐 Cleaning up expired OTP records...';
    
    UPDATE OtpRecords 
    SET IsDeleted = 1 
    WHERE Status IN ('expired', 'failed', 'verified')
        AND CreatedAt < @CleanupDate 
        AND IsDeleted = 0;
        
    SET @RowsAffected = @@ROWCOUNT;
    PRINT 'Marked ' + CAST(@RowsAffected AS NVARCHAR(10)) + ' expired OTP records for deletion';
    
    -- Clean up old failed OTP attempts (older than 30 days)
    PRINT '';
    PRINT '❌ Cleaning up old failed OTP attempts...';
    
    UPDATE FailedOtpAttempts 
    SET IsDeleted = 1 
    WHERE CreatedAt < @CleanupDate 
        AND IsDeleted = 0;
        
    SET @RowsAffected = @@ROWCOUNT;
    PRINT 'Marked ' + CAST(@RowsAffected AS NVARCHAR(10)) + ' old failed OTP attempts for deletion';
    
    -- Clean up old successful login attempts (keep failures for security analysis)
    PRINT '';
    PRINT '✅ Cleaning up old successful login attempts...';
    
    DELETE FROM LoginAttempts 
    WHERE IsSuccess = 1 
        AND CreatedAt < @CleanupDate;
        
    SET @RowsAffected = @@ROWCOUNT;
    PRINT 'Deleted ' + CAST(@RowsAffected AS NVARCHAR(10)) + ' old successful login attempts';
    
    -- Clean up old successful membership attempts
    PRINT '';
    PRINT '👥 Cleaning up old successful membership attempts...';
    
    UPDATE MembershipAttempts 
    SET IsDeleted = 1 
    WHERE IsSuccess = 1 
        AND CreatedAt < @CleanupDate 
        AND IsDeleted = 0;
        
    SET @RowsAffected = @@ROWCOUNT;  
    PRINT 'Marked ' + CAST(@RowsAffected AS NVARCHAR(10)) + ' old successful membership attempts for deletion';
    
    -- Clean up old event log entries (older than 90 days)
    PRINT '';
    PRINT '📝 Cleaning up old event log entries...';
    
    DELETE FROM EventLog 
    WHERE CreatedAt < DATEADD(day, -90, GETUTCDATE());
        
    SET @RowsAffected = @@ROWCOUNT;
    PRINT 'Deleted ' + CAST(@RowsAffected AS NVARCHAR(10)) + ' old event log entries';
    
    -- Commit the cleanup
    COMMIT TRANSACTION CleanupTransaction;
    
    PRINT '';
    PRINT '✅ CLEANUP COMPLETED SUCCESSFULLY!';
    PRINT 'Completed: ' + CONVERT(NVARCHAR(30), GETUTCDATE(), 127);
    
END TRY
BEGIN CATCH
    -- Rollback on error
    ROLLBACK TRANSACTION CleanupTransaction;
    
    PRINT '';
    PRINT '❌ CLEANUP FAILED!';
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'All changes have been rolled back.';
    
    THROW;
END CATCH;
GO

PRINT 'Cleanup script completed.';
GO
