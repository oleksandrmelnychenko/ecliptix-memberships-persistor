-- ============================================
-- Object: UpdateVerificationFlowStatus Procedure
-- Type: Verification Procedure
-- Purpose: Updates verification flow status with automatic expiration handling
-- Author: Oleksandr Melnychenko
-- Created: 2024-12-13
-- Modified: 2025-09-15 - Extracted from monolithic script
-- Dependencies: VerificationFlows table
-- ============================================

USE [EcliptixMemberships];
GO

-- Drop existing procedure if exists (for clean deployment)
IF OBJECT_ID('dbo.UpdateVerificationFlowStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpdateVerificationFlowStatus;
GO

-- Create UpdateVerificationFlowStatus procedure
-- Updates verification flow status with conditional expiration extension
CREATE PROCEDURE dbo.UpdateVerificationFlowStatus
    @FlowUniqueId UNIQUEIDENTIFIER,
    @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.VerificationFlows
    SET Status = @NewStatus,
        ExpiresAt = CASE
            WHEN @NewStatus = 'verified' THEN DATEADD(hour, 24, GETUTCDATE())
            ELSE ExpiresAt
        END
    WHERE UniqueId = @FlowUniqueId AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

PRINT '✅ UpdateVerificationFlowStatus procedure created successfully';
GO