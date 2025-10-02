using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class UpdateMobileNumberStoredProcs : Migration
    {
        private string GetScript(string relativePath)
        {
            var baseDir = AppContext.BaseDirectory;
            var fullPath = Path.Combine(baseDir, "StoredProcedures", "Scripts", relativePath);
            return File.ReadAllText(fullPath);
        }

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Update SP_VerifyMobileForSecretKeyRecovery: PhoneNumberUniqueId → MobileNumberUniqueId in result set
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_VerifyMobileForSecretKeyRecovery.sql")));

            // Update SP_GetMobileNumber: Convert from OUTPUT params to result set, rename parameter
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_GetMobileNumber.sql")));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No down migration - parameter and structure changes are breaking
        }
    }
}
