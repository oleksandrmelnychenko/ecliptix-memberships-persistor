using EcliptixPersistorMigrator.Configuration;
using EcliptixPersistorMigrator.Core.Enums;

namespace EcliptixPersistorMigrator.Core.Domain;

public sealed record CommandResult
{
    public required OperationResult Result { get; init; }
    public string? Message { get; init; }
    public Exception? Exception { get; init; }
    public int ExitCode { get; init; }
    public Dictionary<string, object> Data { get; init; } = new();
    public TimeSpan ExecutionTime { get; init; }

    public bool IsSuccess => Result == OperationResult.Success;
    public bool IsFailure => Result == OperationResult.Failed;

    public static CommandResult Success(string? message = null, int exitCode = Constants.Numeric.Zero, Dictionary<string, object>? data = null)
        => new()
        {
            Result = OperationResult.Success,
            Message = message,
            ExitCode = exitCode,
            Data = data ?? new()
        };

    public static CommandResult Failure(string message, Exception? exception = null, int exitCode = Constants.Numeric.One)
        => new()
        {
            Result = OperationResult.Failed,
            Message = message,
            Exception = exception,
            ExitCode = exitCode
        };


    public static CommandResult NoChanges(string? message = null)
        => new()
        {
            Result = OperationResult.NoChanges,
            Message = message ?? "No changes required"
        };
}

public sealed record ValidationResult
{
    public required bool IsValid { get; init; }
    public ICollection<ValidationError> Errors { get; init; } = new List<ValidationError>();
    public ICollection<ValidationWarning> Warnings { get; init; } = new List<ValidationWarning>();

    public static ValidationResult Valid() => new() { IsValid = true };

    public static ValidationResult Invalid(params ValidationError[] errors)
        => new() { IsValid = false, Errors = errors.ToList() };

}

public sealed record ValidationError
{
    public required string Message { get; init; }
}

public sealed record ValidationWarning
{
    public required string Message { get; init; }
}