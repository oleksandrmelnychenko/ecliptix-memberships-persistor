using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class Refactor : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_PhoneNumber",
                table: "LoginAttempts");

            migrationBuilder.RenameColumn(
                name: "PhoneNumberId",
                table: "VerificationFlows",
                newName: "MobileNumberId");

            migrationBuilder.RenameIndex(
                name: "IX_VerificationFlows_PhoneNumberId",
                table: "VerificationFlows",
                newName: "IX_VerificationFlows_MobileNumberId");

            migrationBuilder.RenameColumn(
                name: "PhoneNumber",
                table: "MobileNumbers",
                newName: "Number");

            migrationBuilder.RenameIndex(
                name: "IX_MobileNumbers_PhoneNumber_Region",
                table: "MobileNumbers",
                newName: "IX_MobileNumbers_MobileNumber_Region");

            migrationBuilder.RenameColumn(
                name: "PhoneNumberId",
                table: "MobileDevices",
                newName: "MobileNumberId");

            migrationBuilder.RenameIndex(
                name: "IX_MobileDevices_PhoneNumberId",
                table: "MobileDevices",
                newName: "IX_MobileDevices_MobileNumberId");

            migrationBuilder.RenameColumn(
                name: "PhoneNumberId",
                table: "Memberships",
                newName: "MobileNumberId");

            migrationBuilder.RenameIndex(
                name: "IX_Memberships_PhoneNumberId",
                table: "Memberships",
                newName: "IX_Memberships_MobileNumberId");

            migrationBuilder.RenameColumn(
                name: "PhoneNumber",
                table: "LoginAttempts",
                newName: "MobileNumber");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_MobileNumber",
                table: "LoginAttempts",
                column: "MobileNumber",
                filter: "IsDeleted = 0 AND MobileNumber IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_MobileNumber",
                table: "LoginAttempts");

            migrationBuilder.RenameColumn(
                name: "MobileNumberId",
                table: "VerificationFlows",
                newName: "PhoneNumberId");

            migrationBuilder.RenameIndex(
                name: "IX_VerificationFlows_MobileNumberId",
                table: "VerificationFlows",
                newName: "IX_VerificationFlows_PhoneNumberId");

            migrationBuilder.RenameColumn(
                name: "Number",
                table: "MobileNumbers",
                newName: "PhoneNumber");

            migrationBuilder.RenameIndex(
                name: "IX_MobileNumbers_MobileNumber_Region",
                table: "MobileNumbers",
                newName: "IX_MobileNumbers_PhoneNumber_Region");

            migrationBuilder.RenameColumn(
                name: "MobileNumberId",
                table: "MobileDevices",
                newName: "PhoneNumberId");

            migrationBuilder.RenameIndex(
                name: "IX_MobileDevices_MobileNumberId",
                table: "MobileDevices",
                newName: "IX_MobileDevices_PhoneNumberId");

            migrationBuilder.RenameColumn(
                name: "MobileNumberId",
                table: "Memberships",
                newName: "PhoneNumberId");

            migrationBuilder.RenameIndex(
                name: "IX_Memberships_MobileNumberId",
                table: "Memberships",
                newName: "IX_Memberships_PhoneNumberId");

            migrationBuilder.RenameColumn(
                name: "MobileNumber",
                table: "LoginAttempts",
                newName: "PhoneNumber");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_PhoneNumber",
                table: "LoginAttempts",
                column: "PhoneNumber",
                filter: "IsDeleted = 0 AND PhoneNumber IS NOT NULL");
        }
    }
}
