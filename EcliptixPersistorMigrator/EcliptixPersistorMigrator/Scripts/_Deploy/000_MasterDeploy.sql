-- ============================================
-- Master Deployment Script
-- Purpose: Orchestrates full database schema deployment in correct order
-- Author: Oleksandr Melnychenko  
-- Created: 2025-09-15
-- Dependencies: All individual component scripts
-- ============================================

USE [EcliptixMemberships];
GO

PRINT '🚀 Starting EcliptixMemberships Database Deployment...';
PRINT 'Timestamp: ' + CONVERT(NVARCHAR(30), GETUTCDATE(), 127);
GO

BEGIN TRANSACTION MasterDeploy;
GO

BEGIN TRY
    -- Step 1: Deploy Tables (Foundation Layer)
    PRINT '📋 Step 1: Deploying Tables...';
    :r 001_DeployTables.sql
    PRINT '✅ Tables deployment completed successfully';
    
    -- Step 2: Deploy Functions (Required by Procedures)
    PRINT '⚡ Step 2: Deploying Functions...';
    :r 002_DeployFunctions.sql
    PRINT '✅ Functions deployment completed successfully';
    
    -- Step 3: Deploy Procedures (Business Logic)
    PRINT '🔧 Step 3: Deploying Procedures...';
    :r 003_DeployProcedures.sql
    PRINT '✅ Procedures deployment completed successfully';
    
    -- Step 4: Deploy Triggers (Automatic Behaviors)
    PRINT '⚡ Step 4: Deploying Triggers...';
    :r 004_DeployTriggers.sql  
    PRINT '✅ Triggers deployment completed successfully';
    
    -- Commit the transaction
    COMMIT TRANSACTION MasterDeploy;
    
    PRINT '🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!';
    PRINT 'All database objects have been deployed and are ready for use.';
    PRINT 'Completion time: ' + CONVERT(NVARCHAR(30), GETUTCDATE(), 127);
    
END TRY
BEGIN CATCH
    -- Rollback on any error
    ROLLBACK TRANSACTION MasterDeploy;
    
    PRINT '❌ DEPLOYMENT FAILED!';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    PRINT 'Rollback completed. Database state preserved.';
    
    -- Re-raise the error
    THROW;
END CATCH;
GO

PRINT 'Master deployment script completed.';
GO
