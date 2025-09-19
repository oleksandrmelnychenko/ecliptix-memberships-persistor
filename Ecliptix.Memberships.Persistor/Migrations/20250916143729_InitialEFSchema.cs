using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ecliptix.Memberships.Persistor.Migrations
{
    public partial class InitialEFSchema : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Devices",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AppInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DeviceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DeviceType = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Devices", x => x.Id);
                    table.UniqueConstraint("AK_Devices_UniqueId", x => x.UniqueId);
                });

            migrationBuilder.CreateTable(
                name: "EventLogs",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EventType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Severity = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Message = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Details = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    EntityType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    EntityId = table.Column<long>(type: "bigint", nullable: true),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SessionId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    OccurredAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MobileNumbers",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PhoneNumber = table.Column<string>(type: "nvarchar(18)", maxLength: 18, nullable: false),
                    Region = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileNumbers", x => x.Id);
                    table.UniqueConstraint("AK_MobileNumbers_UniqueId", x => x.UniqueId);
                });

            migrationBuilder.CreateTable(
                name: "MobileDevices",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PhoneNumberId = table.Column<long>(type: "bigint", nullable: false),
                    DeviceId = table.Column<long>(type: "bigint", nullable: false),
                    RelationshipType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true, defaultValue: "primary"),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    LastUsedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MobileDevices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MobileDevices_Devices",
                        column: x => x.DeviceId,
                        principalTable: "Devices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MobileDevices_MobileNumbers",
                        column: x => x.PhoneNumberId,
                        principalTable: "MobileNumbers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "VerificationFlows",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PhoneNumberId = table.Column<long>(type: "bigint", nullable: false),
                    AppDeviceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false, defaultValue: "pending"),
                    Purpose = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false, defaultValue: "unspecified"),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    OtpCount = table.Column<short>(type: "smallint", nullable: false, defaultValue: (short)0),
                    ConnectionId = table.Column<long>(type: "bigint", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VerificationFlows", x => x.Id);
                    table.UniqueConstraint("AK_VerificationFlows_UniqueId", x => x.UniqueId);
                    table.CheckConstraint("CHK_VerificationFlows_Purpose", "Purpose IN ('unspecified', 'registration', 'login', 'password_recovery', 'update_phone')");
                    table.CheckConstraint("CHK_VerificationFlows_Status", "Status IN ('pending', 'verified', 'expired', 'failed')");
                    table.ForeignKey(
                        name: "FK_VerificationFlows_Devices",
                        column: x => x.AppDeviceId,
                        principalTable: "Devices",
                        principalColumn: "UniqueId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_VerificationFlows_MobileNumbers",
                        column: x => x.PhoneNumberId,
                        principalTable: "MobileNumbers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Memberships",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PhoneNumberId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AppDeviceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VerificationFlowId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SecureKey = table.Column<byte[]>(type: "VARBINARY(MAX)", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false, defaultValue: "inactive"),
                    CreationStatus = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Memberships", x => x.Id);
                    table.UniqueConstraint("AK_Memberships_UniqueId", x => x.UniqueId);
                    table.CheckConstraint("CHK_Memberships_CreationStatus", "CreationStatus IN ('otp_verified', 'secure_key_set', 'passphrase_set')");
                    table.CheckConstraint("CHK_Memberships_Status", "Status IN ('active', 'inactive')");
                    table.ForeignKey(
                        name: "FK_Memberships_Devices",
                        column: x => x.AppDeviceId,
                        principalTable: "Devices",
                        principalColumn: "UniqueId");
                    table.ForeignKey(
                        name: "FK_Memberships_MobileNumbers",
                        column: x => x.PhoneNumberId,
                        principalTable: "MobileNumbers",
                        principalColumn: "UniqueId");
                    table.ForeignKey(
                        name: "FK_Memberships_VerificationFlows",
                        column: x => x.VerificationFlowId,
                        principalTable: "VerificationFlows",
                        principalColumn: "UniqueId");
                });

            migrationBuilder.CreateTable(
                name: "OtpCodes",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VerificationFlowId = table.Column<long>(type: "bigint", nullable: false),
                    OtpValue = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false, defaultValue: "active"),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AttemptCount = table.Column<short>(type: "smallint", nullable: false, defaultValue: (short)0),
                    VerifiedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OtpCodes", x => x.Id);
                    table.CheckConstraint("CHK_OtpCodes_Status", "Status IN ('active', 'used', 'expired', 'invalid')");
                    table.ForeignKey(
                        name: "FK_OtpCodes_VerificationFlows",
                        column: x => x.VerificationFlowId,
                        principalTable: "VerificationFlows",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LoginAttempts",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MembershipId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ErrorMessage = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SessionId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    AttemptedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    SuccessfulAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LoginAttempts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LoginAttempts_Memberships",
                        column: x => x.MembershipId,
                        principalTable: "Memberships",
                        principalColumn: "UniqueId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MembershipAttempts",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MembershipId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AttemptType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ErrorMessage = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    AttemptedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MembershipAttempts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MembershipAttempts_Memberships",
                        column: x => x.MembershipId,
                        principalTable: "Memberships",
                        principalColumn: "UniqueId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FailedOtpAttempts",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    OtpRecordId = table.Column<long>(type: "bigint", nullable: false),
                    AttemptedValue = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    FailureReason = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    AttemptedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    UniqueId = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "NEWID()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FailedOtpAttempts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FailedOtpAttempts_OtpCodes",
                        column: x => x.OtpRecordId,
                        principalTable: "OtpCodes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Devices_AppInstanceId",
                table: "Devices",
                column: "AppInstanceId");

            migrationBuilder.CreateIndex(
                name: "IX_Devices_CreatedAt",
                table: "Devices",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Devices_DeviceType",
                table: "Devices",
                column: "DeviceType",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "UQ_Devices_DeviceId",
                table: "Devices",
                column: "DeviceId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_Devices_UniqueId",
                table: "Devices",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EventLogs_Entity",
                table: "EventLogs",
                columns: new[] { "EntityType", "EntityId" },
                filter: "IsDeleted = 0 AND EntityType IS NOT NULL AND EntityId IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_EventLogs_EventType",
                table: "EventLogs",
                column: "EventType",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_EventLogs_OccurredAt",
                table: "EventLogs",
                column: "OccurredAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_EventLogs_SessionId",
                table: "EventLogs",
                column: "SessionId",
                filter: "IsDeleted = 0 AND SessionId IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_EventLogs_Severity",
                table: "EventLogs",
                column: "Severity",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_EventLogs_UserId",
                table: "EventLogs",
                column: "UserId",
                filter: "IsDeleted = 0 AND UserId IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "UQ_EventLogs_UniqueId",
                table: "EventLogs",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FailedOtpAttempts_AttemptedAt",
                table: "FailedOtpAttempts",
                column: "AttemptedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_FailedOtpAttempts_IpAddress",
                table: "FailedOtpAttempts",
                column: "IpAddress",
                filter: "IsDeleted = 0 AND IpAddress IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_FailedOtpAttempts_OtpRecordId",
                table: "FailedOtpAttempts",
                column: "OtpRecordId");

            migrationBuilder.CreateIndex(
                name: "UQ_FailedOtpAttempts_UniqueId",
                table: "FailedOtpAttempts",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_AttemptedAt",
                table: "LoginAttempts",
                column: "AttemptedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_IpAddress",
                table: "LoginAttempts",
                column: "IpAddress",
                filter: "IsDeleted = 0 AND IpAddress IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_MembershipId",
                table: "LoginAttempts",
                column: "MembershipId");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_SessionId",
                table: "LoginAttempts",
                column: "SessionId",
                filter: "IsDeleted = 0 AND SessionId IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_LoginAttempts_Status",
                table: "LoginAttempts",
                column: "Status",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "UQ_LoginAttempts_UniqueId",
                table: "LoginAttempts",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempts_AttemptedAt",
                table: "MembershipAttempts",
                column: "AttemptedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempts_IpAddress",
                table: "MembershipAttempts",
                column: "IpAddress",
                filter: "IsDeleted = 0 AND IpAddress IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempts_MembershipId",
                table: "MembershipAttempts",
                column: "MembershipId");

            migrationBuilder.CreateIndex(
                name: "IX_MembershipAttempts_Status",
                table: "MembershipAttempts",
                column: "Status",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "UQ_MembershipAttempts_UniqueId",
                table: "MembershipAttempts",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Memberships_AppDeviceId",
                table: "Memberships",
                column: "AppDeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_Memberships_PhoneNumberId",
                table: "Memberships",
                column: "PhoneNumberId");

            migrationBuilder.CreateIndex(
                name: "IX_Memberships_Status",
                table: "Memberships",
                column: "Status",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Memberships_VerificationFlowId",
                table: "Memberships",
                column: "VerificationFlowId");

            migrationBuilder.CreateIndex(
                name: "UQ_Memberships_ActiveMembership",
                table: "Memberships",
                columns: new[] { "PhoneNumberId", "AppDeviceId", "IsDeleted" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_Memberships_UniqueId",
                table: "Memberships",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_DeviceId",
                table: "MobileDevices",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_IsActive",
                table: "MobileDevices",
                column: "IsActive",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_LastUsedAt",
                table: "MobileDevices",
                column: "LastUsedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0 AND LastUsedAt IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_MobileDevices_PhoneNumberId",
                table: "MobileDevices",
                column: "PhoneNumberId");

            migrationBuilder.CreateIndex(
                name: "UQ_MobileDevices_PhoneDevice",
                table: "MobileDevices",
                columns: new[] { "PhoneNumberId", "DeviceId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ_MobileDevices_UniqueId",
                table: "MobileDevices",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MobileNumbers_CreatedAt",
                table: "MobileNumbers",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MobileNumbers_PhoneNumber_Region",
                table: "MobileNumbers",
                columns: new[] { "PhoneNumber", "Region" },
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_MobileNumbers_Region",
                table: "MobileNumbers",
                column: "Region",
                filter: "IsDeleted = 0 AND Region IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "UQ_MobileNumbers_ActiveNumberRegion",
                table: "MobileNumbers",
                columns: new[] { "PhoneNumber", "Region", "IsDeleted" },
                unique: true,
                filter: "[Region] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "UQ_MobileNumbers_UniqueId",
                table: "MobileNumbers",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_OtpCodes_CreatedAt",
                table: "OtpCodes",
                column: "CreatedAt",
                descending: new bool[0],
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_OtpCodes_ExpiresAt",
                table: "OtpCodes",
                column: "ExpiresAt",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_OtpCodes_Status",
                table: "OtpCodes",
                column: "Status",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_OtpCodes_VerificationFlowId",
                table: "OtpCodes",
                column: "VerificationFlowId");

            migrationBuilder.CreateIndex(
                name: "UQ_OtpCodes_UniqueId",
                table: "OtpCodes",
                column: "UniqueId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_VerificationFlows_AppDeviceId",
                table: "VerificationFlows",
                column: "AppDeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_VerificationFlows_ExpiresAt",
                table: "VerificationFlows",
                column: "ExpiresAt",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "IX_VerificationFlows_PhoneNumberId",
                table: "VerificationFlows",
                column: "PhoneNumberId");

            migrationBuilder.CreateIndex(
                name: "IX_VerificationFlows_Status",
                table: "VerificationFlows",
                column: "Status",
                filter: "IsDeleted = 0");

            migrationBuilder.CreateIndex(
                name: "UQ_VerificationFlows_UniqueId",
                table: "VerificationFlows",
                column: "UniqueId",
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EventLogs");

            migrationBuilder.DropTable(
                name: "FailedOtpAttempts");

            migrationBuilder.DropTable(
                name: "LoginAttempts");

            migrationBuilder.DropTable(
                name: "MembershipAttempts");

            migrationBuilder.DropTable(
                name: "MobileDevices");

            migrationBuilder.DropTable(
                name: "OtpCodes");

            migrationBuilder.DropTable(
                name: "Memberships");

            migrationBuilder.DropTable(
                name: "VerificationFlows");

            migrationBuilder.DropTable(
                name: "Devices");

            migrationBuilder.DropTable(
                name: "MobileNumbers");
        }
    }
}
