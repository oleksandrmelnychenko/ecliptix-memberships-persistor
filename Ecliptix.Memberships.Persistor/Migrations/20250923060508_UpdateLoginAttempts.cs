using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class UpdateLoginAttempts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsSuccess",
                table: "LoginAttempts",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Outcome",
                table: "LoginAttempts",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PhoneNumber",
                table: "LoginAttempts",
                type: "nvarchar(18)",
                maxLength: 18,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Timestamp",
                table: "LoginAttempts",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETUTCDATE()");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_IsSuccess",
                table: "LoginAttempts",
                column: "IsSuccess",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_Outcome",
                table: "LoginAttempts",
                column: "Outcome",
                filter: "IsDeleted = 0 AND Outcome IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_PhoneNumber",
                table: "LoginAttempts",
                column: "PhoneNumber",
                filter: "IsDeleted = 0 AND PhoneNumber IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_Timestamp",
                table: "LoginAttempts",
                column: "Timestamp",
                filter: "IsDeleted = 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_IsSuccess",
                table: "LoginAttempts");

            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_Outcome",
                table: "LoginAttempts");

            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_PhoneNumber",
                table: "LoginAttempts");

            migrationBuilder.DropIndex(
                name: "IX_LoginAttempts_Timestamp",
                table: "LoginAttempts");

            migrationBuilder.DropColumn(
                name: "IsSuccess",
                table: "LoginAttempts");

            migrationBuilder.DropColumn(
                name: "Outcome",
                table: "LoginAttempts");

            migrationBuilder.DropColumn(
                name: "PhoneNumber",
                table: "LoginAttempts");

            migrationBuilder.DropColumn(
                name: "Timestamp",
                table: "LoginAttempts");
        }
    }
}
