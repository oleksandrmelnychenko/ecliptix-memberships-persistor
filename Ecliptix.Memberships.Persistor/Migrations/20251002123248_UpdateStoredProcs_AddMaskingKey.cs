using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class UpdateStoredProcs_AddMaskingKey : Migration
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
            // Update stored procedures to include MaskingKey parameter
            migrationBuilder.Sql(GetScript(Path.Combine("Membership", "SP_LoginMembership.sql")));
            migrationBuilder.Sql(GetScript(Path.Combine("Membership", "SP_UpdateMembershipSecureKey.sql")));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No down migration - stored procedures are backward compatible with CREATE OR ALTER
        }
    }
}
