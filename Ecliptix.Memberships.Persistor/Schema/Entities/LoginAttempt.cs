using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("LoginAttempts")]
public class LoginAttempt
{
    [Key]
    public long Id { get; set; }

    [Required]
    public Guid MembershipId { get; set; }

    [MaxLength(18)]
    public string? PhoneNumber { get; set; }

    [MaxLength(500)]
    public string? Outcome { get; set; }

    public bool IsSuccess { get; set; }

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? ErrorMessage { get; set; }

    [MaxLength(45)]
    public string? IpAddress { get; set; }

    [MaxLength(500)]
    public string? UserAgent { get; set; }

    [MaxLength(100)]
    public string? SessionId { get; set; }

    public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;

    public DateTime? SuccessfulAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    [ForeignKey(nameof(MembershipId))]
    public virtual Membership Membership { get; set; } = null!;
}