using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("OtpCodes")]
public class OtpCode : EntityBase
{
    [Required]
    public long VerificationFlowId { get; set; }

    [Required]
    [MaxLength(10)]
    public string OtpValue { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "active";

    [Required]
    public DateTime ExpiresAt { get; set; }

    public short AttemptCount { get; set; } = 0;

    public DateTime? VerifiedAt { get; set; }

    [ForeignKey(nameof(VerificationFlowId))]
    public virtual VerificationFlow VerificationFlow { get; set; } = null!;

    public virtual ICollection<FailedOtpAttempt> FailedAttempts { get; set; } = new List<FailedOtpAttempt>();
}