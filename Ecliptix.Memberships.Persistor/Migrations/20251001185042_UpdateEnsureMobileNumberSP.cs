using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class UpdateEnsureMobileNumberSP : Migration
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
            // Update SP_EnsureMobileNumber to accept @PhoneNumberString and return result set
            migrationBuilder.Sql(GetScript(Path.Combine("Core", "SP_EnsureMobileNumber.sql")));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No down migration - parameter change is breaking
        }
    }
}
