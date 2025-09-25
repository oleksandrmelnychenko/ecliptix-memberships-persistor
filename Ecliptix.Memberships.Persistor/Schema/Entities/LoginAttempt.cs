using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("LoginAttempts")]
public class LoginAttempt : EntityBase
{
    [Required]
    public Guid MembershipId { get; set; }

    [MaxLength(18)]
    public string? MobileNumber { get; set; }

    [MaxLength(500)]
    public string? Outcome { get; set; }

    public bool IsSuccess { get; set; }

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? ErrorMessage { get; set; }

    [MaxLength(100)]
    public string? SessionId { get; set; }

    public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;

    public DateTime? SuccessfulAt { get; set; }

    [ForeignKey(nameof(MembershipId))]
    public virtual Membership Membership { get; set; } = null!;
}