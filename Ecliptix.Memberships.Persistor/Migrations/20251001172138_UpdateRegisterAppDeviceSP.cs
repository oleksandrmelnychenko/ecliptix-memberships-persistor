using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class UpdateRegisterAppDeviceSP : Migration
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
            // Update SP_RegisterAppDevice to return result set instead of OUTPUT parameters
            migrationBuilder.Sql(GetScript(Path.Combine("Core", "SP_RegisterAppDevice.sql")));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No down migration - the old version had OUTPUT parameters which are incompatible
        }
    }
}
