using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("FailedOtpAttempts")]
public class FailedOtpAttempt : EntityBase
{
    [Required]
    public long OtpRecordId { get; set; }

    [Required]
    [MaxLength(10)]
    public string AttemptedValue { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string FailureReason { get; set; } = string.Empty;

    public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(OtpRecordId))]
    public virtual OtpCode OtpRecord { get; set; } = null!;
}