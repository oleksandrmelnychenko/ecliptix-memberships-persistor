using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("VerificationFlows")]
public class VerificationFlow
{
    [Key]
    public long Id { get; set; }

    [Required]
    public long MobileNumberId { get; set; }

    [Required]
    public Guid AppDeviceId { get; set; }

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "pending";

    [Required]
    [MaxLength(30)]
    public string Purpose { get; set; } = "unspecified";

    [Required]
    public DateTime ExpiresAt { get; set; }

    public short OtpCount { get; set; } = 0;

    public long? ConnectionId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    [ForeignKey(nameof(MobileNumberId))]
    public virtual MobileNumber MobileNumber { get; set; } = null!;

    [ForeignKey(nameof(AppDeviceId))]
    public virtual Device AppDevice { get; set; } = null!;

    public virtual ICollection<OtpCode> OtpCodes { get; set; } = new List<OtpCode>();
    public virtual ICollection<Membership> Memberships { get; set; } = new List<Membership>();
}