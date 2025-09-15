namespace EcliptixPersistorMigrator.Core.Enums;

public enum ExecutionMode
{
    Normal,
    DryRun,
    Force,
    Verbose
}

public enum MigrationState
{
    Pending
}

public enum OperationResult
{
    Success,
    Failed,
    NoChanges
}