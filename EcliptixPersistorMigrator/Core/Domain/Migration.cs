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

