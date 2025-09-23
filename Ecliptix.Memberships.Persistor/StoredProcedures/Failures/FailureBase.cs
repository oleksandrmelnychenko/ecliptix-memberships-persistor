namespace Ecliptix.Memberships.Persistor.StoredProcedures.Failures;

public interface IFailureBase
{
    object ToStructuredLog();
}

public abstract record FailureBase(string Message, Exception? InnerException = null) : IFailureBase
{
    protected DateTime Timestamp { get; } = DateTime.UtcNow;

    public abstract object ToStructuredLog();
}