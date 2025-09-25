using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("MembershipAttempts")]
public class MembershipAttempt : EntityBase
{
    [Required]
    public Guid MembershipId { get; set; }

    [Required]
    [MaxLength(50)]
    public string AttemptType { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? ErrorMessage { get; set; }

    public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(MembershipId))]
    public virtual Membership Membership { get; set; } = null!;
}