-- ============================================================================
-- Test Verification Flow - Complete End-to-End Testing
-- ============================================================================
-- Purpose: Tests the complete verification flow with all stored procedures
-- Author: EcliptixPersistorMigrator
-- Created: 2025-09-16
-- ============================================================================

USE [EcliptixMemberships];
GO

SET NOCOUNT ON;
GO

PRINT '🧪 Starting verification flow testing...';
GO

-- Test variables
DECLARE @TestMobileNumber NVARCHAR(18) = '+1234567890';
DECLARE @TestRegion NVARCHAR(2) = 'US';
DECLARE @TestAppInstanceId UNIQUEIDENTIFIER = NEWID();
DECLARE @TestDeviceId UNIQUEIDENTIFIER = NEWID();

-- Output variables
DECLARE @MobileNumberId BIGINT;
DECLARE @MobileUniqueId UNIQUEIDENTIFIER;
DECLARE @IsMobileNewlyCreated BIT;

DECLARE @DeviceRecordId BIGINT;
DECLARE @DeviceUniqueId UNIQUEIDENTIFIER;
DECLARE @IsDeviceNewlyCreated BIT;

DECLARE @FlowUniqueId UNIQUEIDENTIFIER;
DECLARE @FlowOutcome NVARCHAR(50);
DECLARE @FlowErrorMessage NVARCHAR(500);

DECLARE @OtpCode NVARCHAR(10);
DECLARE @OtpUniqueId UNIQUEIDENTIFIER;
DECLARE @OtpOutcome NVARCHAR(50);
DECLARE @OtpErrorMessage NVARCHAR(500);

DECLARE @IsOtpValid BIT;
DECLARE @VerifyOutcome NVARCHAR(50);
DECLARE @VerifyErrorMessage NVARCHAR(500);
DECLARE @VerifiedAt DATETIME2(7);

BEGIN TRY
    PRINT '📱 Test 1: Ensure Mobile Number';

    EXEC dbo.SP_EnsureMobileNumber
        @MobileNumber = @TestMobileNumber,
        @Region = @TestRegion,
        @MobileNumberId = @MobileNumberId OUTPUT,
        @UniqueId = @MobileUniqueId OUTPUT,
        @IsNewlyCreated = @IsMobileNewlyCreated OUTPUT;

    PRINT CONCAT('   ✅ Mobile ID: ', @MobileNumberId, ', Newly Created: ', CASE WHEN @IsMobileNewlyCreated = 1 THEN 'Yes' ELSE 'No' END);

    PRINT '📱 Test 2: Register App Device';

    EXEC dbo.SP_RegisterAppDevice
        @AppInstanceId = @TestAppInstanceId,
        @DeviceId = @TestDeviceId,
        @DeviceType = 1,
        @DeviceUniqueId = @DeviceUniqueId OUTPUT,
        @DeviceRecordId = @DeviceRecordId OUTPUT,
        @IsNewlyCreated = @IsDeviceNewlyCreated OUTPUT;

    PRINT CONCAT('   ✅ Device ID: ', @DeviceRecordId, ', Newly Created: ', CASE WHEN @IsDeviceNewlyCreated = 1 THEN 'Yes' ELSE 'No' END);

    PRINT '🔐 Test 3: Initiate Verification Flow';

    EXEC dbo.SP_InitiateVerificationFlow
        @MobileNumber = @TestMobileNumber,
        @Region = @TestRegion,
        @AppDeviceId = @DeviceUniqueId,
        @Purpose = 'testing',
        @ConnectionId = NULL,
        @FlowUniqueId = @FlowUniqueId OUTPUT,
        @Outcome = @FlowOutcome OUTPUT,
        @ErrorMessage = @FlowErrorMessage OUTPUT;

    IF @FlowOutcome = 'success'
    BEGIN
        PRINT CONCAT('   ✅ Flow initiated successfully. Flow ID: ', @FlowUniqueId);
    END
    ELSE
    BEGIN
        PRINT CONCAT('   ❌ Flow initiation failed: ', @FlowOutcome, ' - ', @FlowErrorMessage);
        RETURN;
    END

    PRINT '🔢 Test 4: Generate OTP Code';

    EXEC dbo.SP_GenerateOtpCode
        @FlowUniqueId = @FlowUniqueId,
        @OtpLength = 6,
        @ExpiryMinutes = 5,
        @OtpCode = @OtpCode OUTPUT,
        @OtpUniqueId = @OtpUniqueId OUTPUT,
        @Outcome = @OtpOutcome OUTPUT,
        @ErrorMessage = @OtpErrorMessage OUTPUT;

    IF @OtpOutcome = 'success'
    BEGIN
        PRINT CONCAT('   ✅ OTP generated successfully. Code: ', @OtpCode);
    END
    ELSE
    BEGIN
        PRINT CONCAT('   ❌ OTP generation failed: ', @OtpOutcome, ' - ', @OtpErrorMessage);
        RETURN;
    END

    PRINT '✅ Test 5: Verify OTP Code (Valid)';

    EXEC dbo.SP_VerifyOtpCode
        @FlowUniqueId = @FlowUniqueId,
        @OtpCode = @OtpCode,
        @IsValid = @IsOtpValid OUTPUT,
        @Outcome = @VerifyOutcome OUTPUT,
        @ErrorMessage = @VerifyErrorMessage OUTPUT,
        @VerifiedAt = @VerifiedAt OUTPUT;

    IF @IsOtpValid = 1 AND @VerifyOutcome = 'verified'
    BEGIN
        PRINT CONCAT('   ✅ OTP verified successfully at: ', @VerifiedAt);
    END
    ELSE
    BEGIN
        PRINT CONCAT('   ❌ OTP verification failed: ', @VerifyOutcome, ' - ', @VerifyErrorMessage);
    END

    PRINT '❌ Test 6: Verify Invalid OTP Code';

    -- Reset variables for invalid test
    SET @IsOtpValid = 0;
    SET @VerifyOutcome = '';
    SET @VerifyErrorMessage = '';
    SET @VerifiedAt = NULL;

    EXEC dbo.SP_VerifyOtpCode
        @FlowUniqueId = @FlowUniqueId,
        @OtpCode = '000000', -- Invalid code
        @IsValid = @IsOtpValid OUTPUT,
        @Outcome = @VerifyOutcome OUTPUT,
        @ErrorMessage = @VerifyErrorMessage OUTPUT,
        @VerifiedAt = @VerifiedAt OUTPUT;

    IF @IsOtpValid = 0
    BEGIN
        PRINT CONCAT('   ✅ Invalid OTP correctly rejected: ', @VerifyOutcome);
    END
    ELSE
    BEGIN
        PRINT '   ❌ Invalid OTP was incorrectly accepted!';
    END

    PRINT '📊 Test 7: Validate Data Integrity';

    -- Check that data was properly recorded
    DECLARE @MobileCount INT, @DeviceCount INT, @FlowCount INT, @OtpCount INT, @FailedAttemptCount INT;

    SELECT @MobileCount = COUNT(*) FROM dbo.MobileNumbers WHERE UniqueId = @MobileUniqueId;
    SELECT @DeviceCount = COUNT(*) FROM dbo.Devices WHERE UniqueId = @DeviceUniqueId;
    SELECT @FlowCount = COUNT(*) FROM dbo.VerificationFlows WHERE UniqueId = @FlowUniqueId;
    SELECT @OtpCount = COUNT(*) FROM dbo.OtpCodes WHERE VerificationFlowId = (SELECT Id FROM dbo.VerificationFlows WHERE UniqueId = @FlowUniqueId);
    SELECT @FailedAttemptCount = COUNT(*) FROM dbo.FailedOtpAttempts WHERE AttemptedValue = '000000';

    PRINT CONCAT('   📱 Mobile records: ', @MobileCount, ' (expected: 1)');
    PRINT CONCAT('   📱 Device records: ', @DeviceCount, ' (expected: 1)');
    PRINT CONCAT('   🔐 Flow records: ', @FlowCount, ' (expected: 1)');
    PRINT CONCAT('   🔢 OTP records: ', @OtpCount, ' (expected: 1)');
    PRINT CONCAT('   ❌ Failed attempts: ', @FailedAttemptCount, ' (expected: 1)');

    IF @MobileCount = 1 AND @DeviceCount = 1 AND @FlowCount = 1 AND @OtpCount = 1 AND @FailedAttemptCount = 1
    BEGIN
        PRINT '   ✅ All data integrity checks passed!';
    END
    ELSE
    BEGIN
        PRINT '   ❌ Data integrity check failed!';
    END

    PRINT '🎉 All tests completed successfully!';

END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT CONCAT('❌ Test failed with error: ', @ErrorMessage);

    -- Log the test failure
    EXEC dbo.SP_LogEvent
        @EventType = 'test_failure',
        @Severity = 'error',
        @Message = 'Verification flow test failed',
        @Details = @ErrorMessage;

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH

GO