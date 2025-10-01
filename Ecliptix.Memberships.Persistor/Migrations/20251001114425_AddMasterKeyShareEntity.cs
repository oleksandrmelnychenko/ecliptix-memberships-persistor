using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class AddMasterKeyShareEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "MembershipId",
                table: "LoginAttempts",
                newName: "MembershipUniqueId");

            migrationBuilder.RenameIndex(
                name: "IX_LoginAttempts_MembershipId",
                table: "LoginAttempts",
                newName: "IX_LoginAttempts_MembershipUniqueId");

            migrationBuilder.CreateTable(
                name: "MasterKeyShares",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MembershipUniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ShareIndex = table.Column<int>(type: "int", nullable: false),
                    EncryptedShare = table.Column<byte[]>(type: "VARBINARY(MAX)", nullable: false),
                    ShareMetadata = table.Column<string>(type: "NVARCHAR(MAX)", nullable: false),
                    StorageLocation = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MasterKeyShares", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MasterKeyShares_Memberships",
                        column: x => x.MembershipUniqueId,
                        principalTable: "Memberships",
                        principalColumn: "UniqueId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_MasterKeyShare_CreatedAt",
                table: "MasterKeyShares",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MasterKeyShare_UpdatedAt",
                table: "MasterKeyShares",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MasterKeyShares_MembershipUniqueId",
                table: "MasterKeyShares",
                column: "MembershipUniqueId");

            migrationBuilder.CreateIndex(
                name: "UQ_MasterKeyShare_UniqueId",
                table: "MasterKeyShares",
                column: "UniqueId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MasterKeyShares");

            migrationBuilder.RenameColumn(
                name: "MembershipUniqueId",
                table: "LoginAttempts",
                newName: "MembershipId");

            migrationBuilder.RenameIndex(
                name: "IX_LoginAttempts_MembershipUniqueId",
                table: "LoginAttempts",
                newName: "IX_LoginAttempts_MembershipId");
        }
    }
}
