namespace Ecliptix.Memberships.Persistor.Schema.Entities;

public class LoginAttempt : EntityBase
{
    public Guid MembershipUniqueId { get; set; }

    public string? MobileNumber { get; set; }

    public string? Outcome { get; set; }

    public bool IsSuccess { get; set; }

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public string Status { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }

    public string? SessionId { get; set; }

    public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;

    public DateTime? SuccessfulAt { get; set; }

    public virtual Membership? Membership { get; set; }
}