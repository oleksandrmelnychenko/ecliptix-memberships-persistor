using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    public partial class DeployStoredProcedures : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. UTILITIES
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Utilities/SP_LogEvent.sql"));

            // 2. CORE
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Core/SP_EnsureMobileNumber.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Core/SP_RegisterAppDevice.sql"));

            // 3. MEMBERSHIP
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Membership/SP_CreateMembership.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Membership/SP_LogLoginAttempt.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Membership/SP_LoginMembership.sql"));

            // 4. VERIFICATION
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_InitiateVerificationFlow.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_GenerateOtpCode.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_VerifyOtpCode.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_RequestResendOtpCode.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_UpdateVerificationFlowStatus.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_VerifyPhoneForSecretKeyRecovery.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_GetMobileNumber.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_UpdateOtpStatus.sql"));
            migrationBuilder.Sql(File.ReadAllText("StoredProcedures/Scripts/Verification/SP_ExpireAssociatedOtp.sql"));
            
            // 5. FINAL LOG
            migrationBuilder.Sql(@"
            EXEC dbo.SP_LogEvent
                @EventType = 'stored_procedures_deployed',
                @Severity = 'info',
                @Message = 'All stored procedures deployed successfully',
                @EntityType = 'System';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_LogEvent");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_EnsureMobileNumber");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_RegisterAppDevice");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_CreateMembership");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_LogLoginAttempt");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_LoginMembership");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_InitiateVerificationFlow");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_GenerateOtpCode");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_VerifyOtpCode");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_RequestResendOtpCode");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_UpdateVerificationFlowStatus");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_VerifyPhoneForSecretKeyRecovery");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_GetMobileNumber");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_UpdateOtpStatus");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_ExpireAssociatedOtp");
        }
    }
}
