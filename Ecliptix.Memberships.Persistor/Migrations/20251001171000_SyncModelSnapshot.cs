using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class SyncModelSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Empty migration - OtpSalt column already added in DeployStoredProcedures migration
            // This migration only exists to synchronize the model snapshot
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Nothing to revert
        }
    }
}
