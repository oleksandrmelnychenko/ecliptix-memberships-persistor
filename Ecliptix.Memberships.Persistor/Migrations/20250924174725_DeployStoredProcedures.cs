using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    public partial class DeployStoredProcedures : Migration
    {
        private string GetScript(string relativePath)
        {
            var baseDir = AppContext.BaseDirectory;
            var fullPath = Path.Combine(baseDir, "StoredProcedures", "Scripts", relativePath);
            return File.ReadAllText(fullPath);
        }
        
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. UTILITIES
            migrationBuilder.Sql(GetScript(Path.Combine("Utilities", "SP_LogEvent.sql")));

            // 2. CORE
            migrationBuilder.Sql(GetScript(Path.Combine("Core", "SP_EnsureMobileNumber.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Core", "SP_RegisterAppDevice.sql")));

            // 3. MEMBERSHIP
            migrationBuilder.Sql(GetScript(Path.Combine("Membership", "SP_CreateMembership.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Membership", "SP_LogLoginAttempt.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Membership", "SP_LoginMembership.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Membership", "SP_UpdateMembershipSecureKey.sql")));

            // 4. VERIFICATION (Add OtpSalt column first)
            migrationBuilder.AddColumn<string>(
                name: "OtpSalt",
                table: "OtpCodes",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_InitiateVerificationFlow.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_InsertOtpRecord.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_VerifyOtpCode.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_RequestResendOtpCode.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_UpdateVerificationFlowStatus.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_VerifyMobileForSecretKeyRecovery.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_GetMobileNumber.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_UpdateOtpStatus.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_ExpireAssociatedOtp.sql")));
            
            // 5. MASTER KEY SHARES
            migrationBuilder.Sql(GetScript(Path.Combine("MasterKeyShare", "SP_InsertMasterKeyShares.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("MasterKeyShare", "SP_GetMasterKeySharesByMembershipId.sql")));
            
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
            // Drop procedures
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_LogEvent");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_EnsureMobileNumber");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_RegisterAppDevice");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_CreateMembership");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_LogLoginAttempt");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_LoginMembership");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_UpdateMembershipSecureKey");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_InitiateVerificationFlow");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_InsertOtpRecord");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_VerifyOtpCode");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_RequestResendOtpCode");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_UpdateVerificationFlowStatus");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_VerifyMobileForSecretKeyRecovery");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_GetMobileNumber");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_UpdateOtpStatus");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_ExpireAssociatedOtp");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_GetMasterKeySharesByMembershipId");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.SP_InsertMasterKeyShares");
            migrationBuilder.Sql("DROP TYPE IF EXISTS dbo.MasterKeyShareTableType");

            // Drop column
            migrationBuilder.DropColumn(
                name: "OtpSalt",
                table: "OtpCodes");
        }
    }
}
