using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("FailedOtpAttempts")]
public class FailedOtpAttempt
{
    [Key]
    public long Id { get; set; }

    [Required]
    public long OtpRecordId { get; set; }

    [Required]
    [MaxLength(10)]
    public string AttemptedValue { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string FailureReason { get; set; } = string.Empty;

    public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    [ForeignKey(nameof(OtpRecordId))]
    public virtual OtpCode OtpRecord { get; set; } = null!;
}