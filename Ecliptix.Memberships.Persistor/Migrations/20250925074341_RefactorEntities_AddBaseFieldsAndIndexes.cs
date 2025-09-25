using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    /// <inheritdoc />
    public partial class RefactorEntities_AddBaseFieldsAndIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameIndex(
                name: "UQ_VerificationFlows_UniqueId",
                table: "VerificationFlows",
                newName: "UQ_VerificationFlow_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_OtpCodes_UniqueId",
                table: "OtpCodes",
                newName: "UQ_OtpCode_UniqueId");

            migrationBuilder.RenameIndex(
                name: "IX_OtpCodes_CreatedAt",
                table: "OtpCodes",
                newName: "IX_OtpCode_CreatedAt");

            migrationBuilder.RenameIndex(
                name: "UQ_MobileNumbers_UniqueId",
                table: "MobileNumbers",
                newName: "UQ_MobileNumber_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_MobileDevices_UniqueId",
                table: "MobileDevices",
                newName: "UQ_MobileDevice_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_MembershipAttempts_UniqueId",
                table: "MembershipAttempts",
                newName: "UQ_MembershipAttempt_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_LoginAttempts_UniqueId",
                table: "LoginAttempts",
                newName: "UQ_LoginAttempt_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_FailedOtpAttempts_UniqueId",
                table: "FailedOtpAttempts",
                newName: "UQ_FailedOtpAttempt_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_EventLogs_UniqueId",
                table: "EventLogs",
                newName: "UQ_EventLog_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_Devices_UniqueId",
                table: "Devices",
                newName: "UQ_Device_UniqueId");

            migrationBuilder.RenameIndex(
                name: "IX_Devices_CreatedAt",
                table: "Devices",
                newName: "IX_Device_CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_VerificationFlow_CreatedAt",
                table: "VerificationFlows",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_VerificationFlow_UpdatedAt",
                table: "VerificationFlows",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_OtpCode_UpdatedAt",
                table: "OtpCodes",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MobileNumber_UpdatedAt",
                table: "MobileNumbers",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevice_CreatedAt",
                table: "MobileDevices",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevice_UpdatedAt",
                table: "MobileDevices",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Membership_CreatedAt",
                table: "Memberships",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Membership_UpdatedAt",
                table: "Memberships",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempt_CreatedAt",
                table: "MembershipAttempts",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempt_UpdatedAt",
                table: "MembershipAttempts",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempt_CreatedAt",
                table: "LoginAttempts",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempt_UpdatedAt",
                table: "LoginAttempts",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_FailedOtpAttempt_CreatedAt",
                table: "FailedOtpAttempts",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_FailedOtpAttempt_UpdatedAt",
                table: "FailedOtpAttempts",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_EventLog_CreatedAt",
                table: "EventLogs",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_EventLog_UpdatedAt",
                table: "EventLogs",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Device_UpdatedAt",
                table: "Devices",
                column: "UpdatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VerificationFlow_CreatedAt",
                table: "VerificationFlows");

            migrationBuilder.DropIndex(
                name: "IX_VerificationFlow_UpdatedAt",
                table: "VerificationFlows");

            migrationBuilder.DropIndex(
                name: "IX_OtpCode_UpdatedAt",
                table: "OtpCodes");

            migrationBuilder.DropIndex(
                name: "IX_MobileNumber_UpdatedAt",
                table: "MobileNumbers");

            migrationBuilder.DropIndex(
                name: "IX_MobileDevice_CreatedAt",
                table: "MobileDevices");

            migrationBuilder.DropIndex(
                name: "IX_MobileDevice_UpdatedAt",
                table: "MobileDevices");

            migrationBuilder.DropIndex(
                name: "IX_Membership_CreatedAt",
                table: "Memberships");

            migrationBuilder.DropIndex(
                name: "IX_Membership_UpdatedAt",
                table: "Memberships");

            migrationBuilder.DropIndex(
                name: "IX_MembershipAttempt_CreatedAt",
                table: "MembershipAttempts");

            migrationBuilder.DropIndex(
                name: "IX_MembershipAttempt_UpdatedAt",
                table: "MembershipAttempts");

            migrationBuilder.DropIndex(
                name: "IX_LoginAttempt_CreatedAt",
                table: "LoginAttempts");

            migrationBuilder.DropIndex(
                name: "IX_LoginAttempt_UpdatedAt",
                table: "LoginAttempts");

            migrationBuilder.DropIndex(
                name: "IX_FailedOtpAttempt_CreatedAt",
                table: "FailedOtpAttempts");

            migrationBuilder.DropIndex(
                name: "IX_FailedOtpAttempt_UpdatedAt",
                table: "FailedOtpAttempts");

            migrationBuilder.DropIndex(
                name: "IX_EventLog_CreatedAt",
                table: "EventLogs");

            migrationBuilder.DropIndex(
                name: "IX_EventLog_UpdatedAt",
                table: "EventLogs");

            migrationBuilder.DropIndex(
                name: "IX_Device_UpdatedAt",
                table: "Devices");

            migrationBuilder.RenameIndex(
                name: "UQ_VerificationFlow_UniqueId",
                table: "VerificationFlows",
                newName: "UQ_VerificationFlows_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_OtpCode_UniqueId",
                table: "OtpCodes",
                newName: "UQ_OtpCodes_UniqueId");

            migrationBuilder.RenameIndex(
                name: "IX_OtpCode_CreatedAt",
                table: "OtpCodes",
                newName: "IX_OtpCodes_CreatedAt");

            migrationBuilder.RenameIndex(
                name: "UQ_MobileNumber_UniqueId",
                table: "MobileNumbers",
                newName: "UQ_MobileNumbers_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_MobileDevice_UniqueId",
                table: "MobileDevices",
                newName: "UQ_MobileDevices_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_MembershipAttempt_UniqueId",
                table: "MembershipAttempts",
                newName: "UQ_MembershipAttempts_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_LoginAttempt_UniqueId",
                table: "LoginAttempts",
                newName: "UQ_LoginAttempts_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_FailedOtpAttempt_UniqueId",
                table: "FailedOtpAttempts",
                newName: "UQ_FailedOtpAttempts_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_EventLog_UniqueId",
                table: "EventLogs",
                newName: "UQ_EventLogs_UniqueId");

            migrationBuilder.RenameIndex(
                name: "UQ_Device_UniqueId",
                table: "Devices",
                newName: "UQ_Devices_UniqueId");

            migrationBuilder.RenameIndex(
                name: "IX_Device_CreatedAt",
                table: "Devices",
                newName: "IX_Devices_CreatedAt");
        }
    }
}
