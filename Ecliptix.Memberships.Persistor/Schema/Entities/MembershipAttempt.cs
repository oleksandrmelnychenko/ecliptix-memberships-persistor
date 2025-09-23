using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("MembershipAttempts")]
public class MembershipAttempt
{
    [Key]
    public long Id { get; set; }

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

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    [ForeignKey(nameof(MembershipId))]
    public virtual Membership Membership { get; set; } = null!;
}