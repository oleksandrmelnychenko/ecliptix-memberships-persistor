using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class RemoveIpAddressAndUserAgent : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MembershipAttempts_IpAddress",
                table: "MembershipAttempts");

            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_IpAddress",
                table: "LoginAttempts");

            migrationBuilder.DropIndex(
                name: "IX_FailedOtpAttempts_IpAddress",
                table: "FailedOtpAttempts");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "MembershipAttempts");

            migrationBuilder.DropColumn(
                name: "UserAgent",
                table: "MembershipAttempts");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "LoginAttempts");

            migrationBuilder.DropColumn(
                name: "UserAgent",
                table: "LoginAttempts");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "FailedOtpAttempts");

            migrationBuilder.DropColumn(
                name: "UserAgent",
                table: "FailedOtpAttempts");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "EventLogs");

            migrationBuilder.DropColumn(
                name: "UserAgent",
                table: "EventLogs");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "MembershipAttempts",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserAgent",
                table: "MembershipAttempts",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "LoginAttempts",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserAgent",
                table: "LoginAttempts",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "FailedOtpAttempts",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserAgent",
                table: "FailedOtpAttempts",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "EventLogs",
                type: "nvarchar(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserAgent",
                table: "EventLogs",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempts_IpAddress",
                table: "MembershipAttempts",
                column: "IpAddress",
                filter: "IsDeleted = 0 AND IpAddress IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_IpAddress",
                table: "LoginAttempts",
                column: "IpAddress",
                filter: "IsDeleted = 0 AND IpAddress IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_FailedOtpAttempts_IpAddress",
                table: "FailedOtpAttempts",
                column: "IpAddress",
                filter: "IsDeleted = 0 AND IpAddress IS NOT NULL");
        }
    }
}
