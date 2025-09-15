using EcliptixPersistorMigrator.Core.Enums;

namespace EcliptixPersistorMigrator.Core.Domain;

public sealed record Migration
{
    public required string Name { get; init; }
    public required string FileName { get; init; }
    public required string Content { get; init; }
    public required int Version { get; init; }
    public string? Description { get; init; }
    public MigrationState State { get; init; } = MigrationState.Pending;
    public DateTime? ExecutedAt { get; init; }
    public string? ExecutedBy { get; init; }
    public string? CheckSum { get; init; }
    public TimeSpan? ExecutionTime { get; init; }
    public string? ErrorMessage { get; init; }
}

public sealed record Seed
{
    public required string Name { get; init; }
    public required string FileName { get; init; }
    public required string Content { get; init; }
    public required int Version { get; init; }
    public string? Description { get; init; }
    public MigrationState State { get; init; } = MigrationState.Pending;
    public DateTime? ExecutedAt { get; init; }
    public string? ExecutedBy { get; init; }
    public string? CheckSum { get; init; }
    public TimeSpan? ExecutionTime { get; init; }
    public string? ErrorMessage { get; init; }
}

public sealed record BackupInfo
{
    public required string Name { get; init; }
    public required string FilePath { get; init; }
    public required DateTime CreatedAt { get; init; }
    public long SizeInBytes { get; init; }
    public string? Description { get; init; }
}

public sealed record ExecutionContext
{
    public required string ConnectionString { get; init; }
    public required ExecutionMode Mode { get; init; }
    public bool VerboseLogging { get; init; }
    public CancellationToken CancellationToken { get; init; } = default;
    public string? TargetVersion { get; init; }
    public string? BackupName { get; init; }
    public Dictionary<string, string> Variables { get; init; } = new();
}