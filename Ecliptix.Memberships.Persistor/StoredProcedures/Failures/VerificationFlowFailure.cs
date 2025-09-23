using Ecliptix.Domain.Memberships.Failures;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Failures;

public sealed record VerificationFlowFailure(
    VerificationFlowFailureType FailureType,
    string Message,
    Exception? InnerException = null)
    : FailureBase(Message, InnerException)
{
    public bool IsRecoverable => FailureType switch
    {
        VerificationFlowFailureType.RateLimitExceeded => true,
        VerificationFlowFailureType.SmsSendFailed => true,
        VerificationFlowFailureType.PersistorAccess => true,
        VerificationFlowFailureType.ConcurrencyConflict => true,
        _ => false
    };

    public bool IsSecurityRelated => FailureType switch
    {
        VerificationFlowFailureType.SuspiciousActivity => true,
        VerificationFlowFailureType.RateLimitExceeded => true,
        VerificationFlowFailureType.OtpMaxAttemptsReached => true,
        VerificationFlowFailureType.InvalidOpaque => true,
        _ => false
    };

    public bool IsUserFacing => FailureType switch
    {
        VerificationFlowFailureType.NotFound => true,
        VerificationFlowFailureType.Expired => true,
        VerificationFlowFailureType.Conflict => false,

        VerificationFlowFailureType.InvalidOtp => true,
        VerificationFlowFailureType.OtpExpired => true,
        VerificationFlowFailureType.OtpMaxAttemptsReached => true,
        VerificationFlowFailureType.OtpGenerationFailed => false,

        VerificationFlowFailureType.SmsSendFailed => true,
        VerificationFlowFailureType.PhoneNumberInvalid => true,

        VerificationFlowFailureType.PersistorAccess => false,
        VerificationFlowFailureType.ConcurrencyConflict => false,

        VerificationFlowFailureType.RateLimitExceeded => true,
        VerificationFlowFailureType.SuspiciousActivity => false,

        VerificationFlowFailureType.Validation => true,
        VerificationFlowFailureType.InvalidOpaque => false,
        _ => false
    };

    public static VerificationFlowFailure InvalidOpaque(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.InvalidOpaque,
            details ?? VerificationFlowMessageKeys.InvalidOpaque);
    }

    public static VerificationFlowFailure NotFound(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.NotFound,
            details ?? VerificationFlowMessageKeys.VerificationFlowNotFound);
    }

    public static VerificationFlowFailure InvalidOtp(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.InvalidOtp,
            details ?? VerificationFlowMessageKeys.InvalidOtp);
    }

    public static VerificationFlowFailure OtpMaxAttemptsReached(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.OtpMaxAttemptsReached,
            details ?? VerificationFlowMessageKeys.OtpMaxAttemptsReached);
    }

    public static VerificationFlowFailure
        OtpGenerationFailed(string? details = null, Exception? innerException = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.OtpGenerationFailed,
            details ?? VerificationFlowMessageKeys.OtpGenerationFailed,
            innerException);
    }

    public static VerificationFlowFailure
        PhoneNumberInvalid(string? details = null, Exception? innerException = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.PhoneNumberInvalid,
            details ?? VerificationFlowMessageKeys.PhoneNumberInvalid, innerException);
    }

    public static VerificationFlowFailure
        SmsSendFailed(string? details = null, Exception? innerException = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.SmsSendFailed,
            details ?? VerificationFlowMessageKeys.SmsSendFailed, innerException);
    }

    public static VerificationFlowFailure PersistorAccess(string? details = null, Exception? innerException = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.PersistorAccess,
            details ?? VerificationFlowMessageKeys.DataAccess,
            innerException);
    }

    public static VerificationFlowFailure PersistorAccess(Exception innerException)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.PersistorAccess,
            VerificationFlowMessageKeys.DataAccess,
            innerException);
    }

    public static VerificationFlowFailure ConcurrencyConflict(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.ConcurrencyConflict,
            details ?? VerificationFlowMessageKeys.ConcurrencyConflict);
    }

    public static VerificationFlowFailure RateLimitExceeded(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.RateLimitExceeded,
            details ?? VerificationFlowMessageKeys.RateLimitExceeded);
    }

    public static VerificationFlowFailure Validation(string? details = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.Validation,
            details ?? VerificationFlowMessageKeys.Validation);
    }

    public static VerificationFlowFailure Generic(string? details = null, Exception? innerException = null)
    {
        return new VerificationFlowFailure(VerificationFlowFailureType.Generic,
            details ?? VerificationFlowMessageKeys.Generic,
            innerException);
    }

    public override object ToStructuredLog()
    {
        return new
        {
            FailureType = FailureType.ToString(),
            Message,
            InnerException,
            Timestamp,
            IsUserFacing,
            IsRecoverable,
            IsSecurityRelated
        };
    }
}