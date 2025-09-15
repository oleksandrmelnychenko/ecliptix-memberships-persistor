using System.Data;
using EcliptixPersistorMigrator.Core.Domain;
using EcliptixPersistorMigrator.Core.Enums;

namespace EcliptixPersistorMigrator.Core.Interfaces;

public interface IMigrationRepository
{
    Task<IEnumerable<Migration>> GetAllMigrationsAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<Migration>> GetExecutedMigrationsAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<Migration>> GetPendingMigrationsAsync(CancellationToken cancellationToken = default);
    Task<Migration?> GetMigrationByNameAsync(string name, CancellationToken cancellationToken = default);
    Task<OperationResult> MarkMigrationAsExecutedAsync(Migration migration, CancellationToken cancellationToken = default);
    Task<OperationResult> RemoveMigrationFromJournalAsync(string migrationName, CancellationToken cancellationToken = default);
}

public interface ISeedRepository
{
    Task<IEnumerable<Seed>> GetAllSeedsAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<Seed>> GetExecutedSeedsAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<Seed>> GetPendingSeedsAsync(CancellationToken cancellationToken = default);
    Task<OperationResult> MarkSeedAsExecutedAsync(Seed seed, CancellationToken cancellationToken = default);
}

public interface IDatabaseConnection
{
    Task<bool> TestConnectionAsync(CancellationToken cancellationToken = default);
    Task<T> ExecuteAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default);
    Task ExecuteAsync(Func<Task> operation, CancellationToken cancellationToken = default);
    Task<T> ExecuteInTransactionAsync<T>(Func<IDbTransaction, Task<T>> operation, IsolationLevel isolationLevel = IsolationLevel.ReadCommitted, CancellationToken cancellationToken = default);
    Task ExecuteInTransactionAsync(Func<IDbTransaction, Task> operation, IsolationLevel isolationLevel = IsolationLevel.ReadCommitted, CancellationToken cancellationToken = default);
}

public interface IMigrationEngine
{
    Task<OperationResult> ExecuteMigrationAsync(Migration migration, ExecutionMode mode, CancellationToken cancellationToken = default);
    Task<OperationResult> ExecuteSeedAsync(Seed seed, ExecutionMode mode, CancellationToken cancellationToken = default);
    Task<ValidationResult> ValidateMigrationAsync(Migration migration, CancellationToken cancellationToken = default);
}

public interface IBackupService
{
    Task<OperationResult> CreateBackupAsync(string backupName, CancellationToken cancellationToken = default);
    Task<OperationResult> RestoreBackupAsync(string backupName, CancellationToken cancellationToken = default);
    Task<IEnumerable<BackupInfo>> GetAvailableBackupsAsync(CancellationToken cancellationToken = default);
}