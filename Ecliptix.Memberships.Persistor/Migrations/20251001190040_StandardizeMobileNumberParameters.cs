using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class StandardizeMobileNumberParameters : Migration
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
            // Update SP_EnsureMobileNumber: @PhoneNumberString → @MobileNumber
            migrationBuilder.Sql(GetScript(Path.Combine("Core", "SP_EnsureMobileNumber.sql")));

            // Update SP_VerifyMobileForSecretKeyRecovery: Convert OUTPUT params to result set
            migrationBuilder.Sql(GetScript(Path.Combine("Verification", "SP_VerifyMobileForSecretKeyRecovery.sql")));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No down migration - parameter changes are breaking
        }
    }
}
