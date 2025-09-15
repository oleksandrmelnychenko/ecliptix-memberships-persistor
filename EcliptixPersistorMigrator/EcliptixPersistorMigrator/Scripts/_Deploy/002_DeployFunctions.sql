-- ============================================
-- Functions Deployment Script
-- Purpose: Deploys all functions in dependency order
-- Author: Oleksandr Melnychenko
-- Created: 2025-09-15
-- Dependencies: Tables must be deployed first
-- ============================================

USE [EcliptixMemberships];
GO

PRINT 'Deploying Functions...';
GO

-- Core Functions (Basic utilities)
PRINT 'Deploying Core Functions...';
:r ../03_Functions/Core/001_GetPhoneNumber.sql

-- Verification Functions (Enhanced for workflows)
PRINT 'Deploying Verification Functions...';
:r ../03_Functions/Verification/001_GetFullFlowState.sql
:r ../03_Functions/Verification/002_GetPhoneNumber.sql

PRINT 'All functions deployed successfully!';
GO
