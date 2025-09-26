using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class AddMaskingKey_AndMac : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "MAC (UUID)",
                table: "Memberships",
                type: "VARBINARY(32)",
                nullable: true);

            migrationBuilder.AddColumn<byte[]>(
                name: "Mac",
                table: "Memberships",
                type: "VARBINARY(64)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MAC (UUID)",
                table: "Memberships");

            migrationBuilder.DropColumn(
                name: "Mac",
                table: "Memberships");
        }
    }
}
