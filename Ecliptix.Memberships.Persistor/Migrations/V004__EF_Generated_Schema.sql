IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [Devices] (
    [Id] bigint NOT NULL IDENTITY,
    [AppInstanceId] uniqueidentifier NOT NULL,
    [DeviceId] uniqueidentifier NOT NULL,
    [DeviceType] int NOT NULL DEFAULT 1,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_Devices] PRIMARY KEY ([Id]),
    CONSTRAINT [AK_Devices_UniqueId] UNIQUE ([UniqueId])
);

CREATE TABLE [EventLogs] (
    [Id] bigint NOT NULL IDENTITY,
    [EventType] nvarchar(50) NOT NULL,
    [Severity] nvarchar(20) NOT NULL,
    [Message] nvarchar(200) NOT NULL,
    [Details] nvarchar(4000) NULL,
    [EntityType] nvarchar(100) NULL,
    [EntityId] bigint NULL,
    [UserId] uniqueidentifier NULL,
    [IpAddress] nvarchar(45) NULL,
    [UserAgent] nvarchar(500) NULL,
    [SessionId] nvarchar(100) NULL,
    [OccurredAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_EventLogs] PRIMARY KEY ([Id])
);

CREATE TABLE [MobileNumbers] (
    [Id] bigint NOT NULL IDENTITY,
    [PhoneNumber] nvarchar(18) NOT NULL,
    [Region] nvarchar(2) NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_MobileNumbers] PRIMARY KEY ([Id]),
    CONSTRAINT [AK_MobileNumbers_UniqueId] UNIQUE ([UniqueId])
);

CREATE TABLE [MobileDevices] (
    [Id] bigint NOT NULL IDENTITY,
    [PhoneNumberId] bigint NOT NULL,
    [DeviceId] bigint NOT NULL,
    [RelationshipType] nvarchar(50) NULL DEFAULT N'primary',
    [IsActive] bit NOT NULL DEFAULT CAST(1 AS bit),
    [LastUsedAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_MobileDevices] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_MobileDevices_Devices] FOREIGN KEY ([DeviceId]) REFERENCES [Devices] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_MobileDevices_MobileNumbers] FOREIGN KEY ([PhoneNumberId]) REFERENCES [MobileNumbers] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [VerificationFlows] (
    [Id] bigint NOT NULL IDENTITY,
    [PhoneNumberId] bigint NOT NULL,
    [AppDeviceId] uniqueidentifier NOT NULL,
    [Status] nvarchar(20) NOT NULL DEFAULT N'pending',
    [Purpose] nvarchar(30) NOT NULL DEFAULT N'unspecified',
    [ExpiresAt] datetime2 NOT NULL,
    [OtpCount] smallint NOT NULL DEFAULT CAST(0 AS smallint),
    [ConnectionId] bigint NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_VerificationFlows] PRIMARY KEY ([Id]),
    CONSTRAINT [AK_VerificationFlows_UniqueId] UNIQUE ([UniqueId]),
    CONSTRAINT [CHK_VerificationFlows_Purpose] CHECK (Purpose IN ('unspecified', 'registration', 'login', 'password_recovery', 'update_phone')),
    CONSTRAINT [CHK_VerificationFlows_Status] CHECK (Status IN ('pending', 'verified', 'expired', 'failed')),
    CONSTRAINT [FK_VerificationFlows_Devices] FOREIGN KEY ([AppDeviceId]) REFERENCES [Devices] ([UniqueId]) ON DELETE CASCADE,
    CONSTRAINT [FK_VerificationFlows_MobileNumbers] FOREIGN KEY ([PhoneNumberId]) REFERENCES [MobileNumbers] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [Memberships] (
    [Id] bigint NOT NULL IDENTITY,
    [PhoneNumberId] uniqueidentifier NOT NULL,
    [AppDeviceId] uniqueidentifier NOT NULL,
    [VerificationFlowId] uniqueidentifier NOT NULL,
    [SecureKey] VARBINARY(MAX) NULL,
    [Status] nvarchar(20) NOT NULL DEFAULT N'inactive',
    [CreationStatus] nvarchar(20) NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_Memberships] PRIMARY KEY ([Id]),
    CONSTRAINT [AK_Memberships_UniqueId] UNIQUE ([UniqueId]),
    CONSTRAINT [CHK_Memberships_CreationStatus] CHECK (CreationStatus IN ('otp_verified', 'secure_key_set', 'passphrase_set')),
    CONSTRAINT [CHK_Memberships_Status] CHECK (Status IN ('active', 'inactive')),
    CONSTRAINT [FK_Memberships_Devices] FOREIGN KEY ([AppDeviceId]) REFERENCES [Devices] ([UniqueId]),
    CONSTRAINT [FK_Memberships_MobileNumbers] FOREIGN KEY ([PhoneNumberId]) REFERENCES [MobileNumbers] ([UniqueId]),
    CONSTRAINT [FK_Memberships_VerificationFlows] FOREIGN KEY ([VerificationFlowId]) REFERENCES [VerificationFlows] ([UniqueId])
);

CREATE TABLE [OtpCodes] (
    [Id] bigint NOT NULL IDENTITY,
    [VerificationFlowId] bigint NOT NULL,
    [OtpValue] nvarchar(10) NOT NULL,
    [Status] nvarchar(20) NOT NULL DEFAULT N'active',
    [ExpiresAt] datetime2 NOT NULL,
    [AttemptCount] smallint NOT NULL DEFAULT CAST(0 AS smallint),
    [VerifiedAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_OtpCodes] PRIMARY KEY ([Id]),
    CONSTRAINT [CHK_OtpCodes_Status] CHECK (Status IN ('active', 'used', 'expired', 'invalid')),
    CONSTRAINT [FK_OtpCodes_VerificationFlows] FOREIGN KEY ([VerificationFlowId]) REFERENCES [VerificationFlows] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [LoginAttempts] (
    [Id] bigint NOT NULL IDENTITY,
    [MembershipId] uniqueidentifier NOT NULL,
    [Status] nvarchar(20) NOT NULL,
    [ErrorMessage] nvarchar(500) NULL,
    [IpAddress] nvarchar(45) NULL,
    [UserAgent] nvarchar(500) NULL,
    [SessionId] nvarchar(100) NULL,
    [AttemptedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [SuccessfulAt] datetime2 NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_LoginAttempts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_LoginAttempts_Memberships] FOREIGN KEY ([MembershipId]) REFERENCES [Memberships] ([UniqueId]) ON DELETE CASCADE
);

CREATE TABLE [MembershipAttempts] (
    [Id] bigint NOT NULL IDENTITY,
    [MembershipId] uniqueidentifier NOT NULL,
    [AttemptType] nvarchar(50) NOT NULL,
    [Status] nvarchar(20) NOT NULL,
    [ErrorMessage] nvarchar(500) NULL,
    [IpAddress] nvarchar(45) NULL,
    [UserAgent] nvarchar(500) NULL,
    [AttemptedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_MembershipAttempts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_MembershipAttempts_Memberships] FOREIGN KEY ([MembershipId]) REFERENCES [Memberships] ([UniqueId]) ON DELETE CASCADE
);

CREATE TABLE [FailedOtpAttempts] (
    [Id] bigint NOT NULL IDENTITY,
    [OtpRecordId] bigint NOT NULL,
    [AttemptedValue] nvarchar(10) NOT NULL,
    [FailureReason] nvarchar(50) NOT NULL,
    [IpAddress] nvarchar(45) NULL,
    [UserAgent] nvarchar(500) NULL,
    [AttemptedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [CreatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [UpdatedAt] datetime2 NOT NULL DEFAULT (GETUTCDATE()),
    [IsDeleted] bit NOT NULL DEFAULT CAST(0 AS bit),
    [UniqueId] uniqueidentifier NOT NULL DEFAULT (NEWID()),
    CONSTRAINT [PK_FailedOtpAttempts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_FailedOtpAttempts_OtpCodes] FOREIGN KEY ([OtpRecordId]) REFERENCES [OtpCodes] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_Devices_AppInstanceId] ON [Devices] ([AppInstanceId]);

CREATE INDEX [IX_Devices_CreatedAt] ON [Devices] ([CreatedAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_Devices_DeviceType] ON [Devices] ([DeviceType]) WHERE IsDeleted = 0;

CREATE UNIQUE INDEX [UQ_Devices_DeviceId] ON [Devices] ([DeviceId]);

CREATE UNIQUE INDEX [UQ_Devices_UniqueId] ON [Devices] ([UniqueId]);

CREATE INDEX [IX_EventLogs_Entity] ON [EventLogs] ([EntityType], [EntityId]) WHERE IsDeleted = 0 AND EntityType IS NOT NULL AND EntityId IS NOT NULL;

CREATE INDEX [IX_EventLogs_EventType] ON [EventLogs] ([EventType]) WHERE IsDeleted = 0;

CREATE INDEX [IX_EventLogs_OccurredAt] ON [EventLogs] ([OccurredAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_EventLogs_SessionId] ON [EventLogs] ([SessionId]) WHERE IsDeleted = 0 AND SessionId IS NOT NULL;

CREATE INDEX [IX_EventLogs_Severity] ON [EventLogs] ([Severity]) WHERE IsDeleted = 0;

CREATE INDEX [IX_EventLogs_UserId] ON [EventLogs] ([UserId]) WHERE IsDeleted = 0 AND UserId IS NOT NULL;

CREATE UNIQUE INDEX [UQ_EventLogs_UniqueId] ON [EventLogs] ([UniqueId]);

CREATE INDEX [IX_FailedOtpAttempts_AttemptedAt] ON [FailedOtpAttempts] ([AttemptedAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_FailedOtpAttempts_IpAddress] ON [FailedOtpAttempts] ([IpAddress]) WHERE IsDeleted = 0 AND IpAddress IS NOT NULL;

CREATE INDEX [IX_FailedOtpAttempts_OtpRecordId] ON [FailedOtpAttempts] ([OtpRecordId]);

CREATE UNIQUE INDEX [UQ_FailedOtpAttempts_UniqueId] ON [FailedOtpAttempts] ([UniqueId]);

CREATE INDEX [IX_LoginAttempts_AttemptedAt] ON [LoginAttempts] ([AttemptedAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_LoginAttempts_IpAddress] ON [LoginAttempts] ([IpAddress]) WHERE IsDeleted = 0 AND IpAddress IS NOT NULL;

CREATE INDEX [IX_LoginAttempts_MembershipId] ON [LoginAttempts] ([MembershipId]);

CREATE INDEX [IX_LoginAttempts_SessionId] ON [LoginAttempts] ([SessionId]) WHERE IsDeleted = 0 AND SessionId IS NOT NULL;

CREATE INDEX [IX_LoginAttempts_Status] ON [LoginAttempts] ([Status]) WHERE IsDeleted = 0;

CREATE UNIQUE INDEX [UQ_LoginAttempts_UniqueId] ON [LoginAttempts] ([UniqueId]);

CREATE INDEX [IX_MembershipAttempts_AttemptedAt] ON [MembershipAttempts] ([AttemptedAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_MembershipAttempts_IpAddress] ON [MembershipAttempts] ([IpAddress]) WHERE IsDeleted = 0 AND IpAddress IS NOT NULL;

CREATE INDEX [IX_MembershipAttempts_MembershipId] ON [MembershipAttempts] ([MembershipId]);

CREATE INDEX [IX_MembershipAttempts_Status] ON [MembershipAttempts] ([Status]) WHERE IsDeleted = 0;

CREATE UNIQUE INDEX [UQ_MembershipAttempts_UniqueId] ON [MembershipAttempts] ([UniqueId]);

CREATE INDEX [IX_Memberships_AppDeviceId] ON [Memberships] ([AppDeviceId]);

CREATE INDEX [IX_Memberships_PhoneNumberId] ON [Memberships] ([PhoneNumberId]);

CREATE INDEX [IX_Memberships_Status] ON [Memberships] ([Status]) WHERE IsDeleted = 0;

CREATE INDEX [IX_Memberships_VerificationFlowId] ON [Memberships] ([VerificationFlowId]);

CREATE UNIQUE INDEX [UQ_Memberships_ActiveMembership] ON [Memberships] ([PhoneNumberId], [AppDeviceId], [IsDeleted]);

CREATE UNIQUE INDEX [UQ_Memberships_UniqueId] ON [Memberships] ([UniqueId]);

CREATE INDEX [IX_MobileDevices_DeviceId] ON [MobileDevices] ([DeviceId]);

CREATE INDEX [IX_MobileDevices_IsActive] ON [MobileDevices] ([IsActive]) WHERE IsDeleted = 0;

CREATE INDEX [IX_MobileDevices_LastUsedAt] ON [MobileDevices] ([LastUsedAt] DESC) WHERE IsDeleted = 0 AND LastUsedAt IS NOT NULL;

CREATE INDEX [IX_MobileDevices_PhoneNumberId] ON [MobileDevices] ([PhoneNumberId]);

CREATE UNIQUE INDEX [UQ_MobileDevices_PhoneDevice] ON [MobileDevices] ([PhoneNumberId], [DeviceId]);

CREATE UNIQUE INDEX [UQ_MobileDevices_UniqueId] ON [MobileDevices] ([UniqueId]);

CREATE INDEX [IX_MobileNumbers_CreatedAt] ON [MobileNumbers] ([CreatedAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_MobileNumbers_PhoneNumber_Region] ON [MobileNumbers] ([PhoneNumber], [Region]) WHERE IsDeleted = 0;

CREATE INDEX [IX_MobileNumbers_Region] ON [MobileNumbers] ([Region]) WHERE IsDeleted = 0 AND Region IS NOT NULL;

CREATE UNIQUE INDEX [UQ_MobileNumbers_ActiveNumberRegion] ON [MobileNumbers] ([PhoneNumber], [Region], [IsDeleted]) WHERE [Region] IS NOT NULL;

CREATE UNIQUE INDEX [UQ_MobileNumbers_UniqueId] ON [MobileNumbers] ([UniqueId]);

CREATE INDEX [IX_OtpCodes_CreatedAt] ON [OtpCodes] ([CreatedAt] DESC) WHERE IsDeleted = 0;

CREATE INDEX [IX_OtpCodes_ExpiresAt] ON [OtpCodes] ([ExpiresAt]) WHERE IsDeleted = 0;

CREATE INDEX [IX_OtpCodes_Status] ON [OtpCodes] ([Status]) WHERE IsDeleted = 0;

CREATE INDEX [IX_OtpCodes_VerificationFlowId] ON [OtpCodes] ([VerificationFlowId]);

CREATE UNIQUE INDEX [UQ_OtpCodes_UniqueId] ON [OtpCodes] ([UniqueId]);

CREATE INDEX [IX_VerificationFlows_AppDeviceId] ON [VerificationFlows] ([AppDeviceId]);

CREATE INDEX [IX_VerificationFlows_ExpiresAt] ON [VerificationFlows] ([ExpiresAt]) WHERE IsDeleted = 0;

CREATE INDEX [IX_VerificationFlows_PhoneNumberId] ON [VerificationFlows] ([PhoneNumberId]);

CREATE INDEX [IX_VerificationFlows_Status] ON [VerificationFlows] ([Status]) WHERE IsDeleted = 0;

CREATE UNIQUE INDEX [UQ_VerificationFlows_UniqueId] ON [VerificationFlows] ([UniqueId]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20250916143729_InitialEFSchema', N'9.0.0');

COMMIT;
GO

