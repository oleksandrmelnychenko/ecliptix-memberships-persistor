namespace EcliptixPersistorMigrator.Core.Enums;

public enum ExecutionMode
{
    Normal,
    DryRun,
    Force,
    Silent,
    Verbose
}

public enum MigrationState
{
    Pending,
    Executed,
    Failed,
    Rolled_Back,
    Skipped,
    Unknown
}

public enum OperationResult
{
    Success,
    Failed,
    Warning,
    Cancelled,
    NoChanges
}