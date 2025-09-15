/*
================================================================================
S001: Default Configuration Seed Data
================================================================================
Purpose: Insert default configuration values
Author: Ecliptix Migration Tool
Created: 2024-12-13
================================================================================
*/

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
GO

-- Insert default configuration values
INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('Authentication.MaxFailedAttempts', '5', 'int', 'Maximum failed authentication attempts before lockout', 'Security'),
('Authentication.LockoutDurationMinutes', '5', 'int', 'Duration of account lockout in minutes', 'Security'),
('Authentication.ContextExpirationHours', '24', 'int', 'Default authentication context expiration in hours', 'Security'),
('Authentication.MaxSessionsPerUser', '5', 'int', 'Maximum concurrent sessions per user', 'Security'),
('Authentication.MaxLockoutDuration', '1440', 'int', 'Maximum lockout duration in minutes (24 hours)', 'Security');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('OTP.MaxAttempts', '5', 'int', 'Maximum OTP attempts per flow', 'Security'),
('OTP.ExpirationMinutes', '5', 'int', 'OTP expiration time in minutes', 'Security'),
('OTP.ResendCooldownSeconds', '30', 'int', 'Minimum seconds between OTP resend requests', 'Security'),
('OTP.EnableRateLimitTracking', '1', 'bool', 'Enable OTP rate limit tracking and enforcement', 'Security');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('RateLimit.MaxFlowsPerHour', '100', 'int', 'Maximum verification flows per phone number per hour', 'Security'),
('RateLimit.WindowHours', '1', 'int', 'Rate limiting window in hours', 'Security');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('Database.CleanupBatchSize', '1000', 'int', 'Batch size for cleanup operations', 'Performance'),
('Database.RetentionDays', '90', 'int', 'Data retention period in days', 'Performance');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('Monitoring.EnableMetrics', '1', 'bool', 'Enable performance metrics collection', 'Monitoring'),
('Monitoring.MetricsBatchSize', '100', 'int', 'Batch size for metrics processing', 'Monitoring');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('Audit.RetentionDays', '365', 'int', 'Audit log retention period in days', 'Compliance'),
('Audit.LogValidations', '0', 'bool', 'Enable detailed validation logging (high frequency)', 'Compliance'),
('Audit.LogOtpChanges', '1', 'bool', 'Enable detailed OTP change logging in triggers', 'Compliance'),
('Audit.LogMembershipChanges', '1', 'bool', 'Enable detailed membership change logging', 'Compliance');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('Membership.SuspiciousActivityThreshold', '3', 'int', 'Unique IPs threshold for suspicious activity', 'Security'),
('Membership.EnableGeoBlocking', '0', 'bool', 'Enable geographic-based access blocking', 'Security');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('VerificationFlow.DefaultExpirationMinutes', '5', 'int', 'Default verification flow expiration in minutes', 'Security');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('CircuitBreaker.FailureThreshold', '5', 'int', 'Number of failures before circuit opens', 'Resilience'),
('CircuitBreaker.SuccessThreshold', '3', 'int', 'Number of successes to close circuit', 'Resilience'),
('CircuitBreaker.TimeoutMinutes', '1', 'int', 'Circuit breaker timeout in minutes', 'Resilience');

INSERT INTO dbo.SystemConfiguration (ConfigKey, ConfigValue, DataType, Description, Category) VALUES
('Maintenance.AutoCleanupEnabled', '1', 'bool', 'Enable automatic cleanup procedures', 'Maintenance'),
('Maintenance.CleanupScheduleHours', '2', 'int', 'Hour of day to run cleanup (24-hour format)', 'Maintenance');

PRINT 'S001: Default Configuration Seed Data - Completed Successfully';
GO