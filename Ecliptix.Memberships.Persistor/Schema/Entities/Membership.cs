using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("Memberships")]
public class Membership : EntityBase
{
    [Required]
    public Guid MobileNumberId { get; set; }

    [Required]
    public Guid AppDeviceId { get; set; }

    [Required]
    public Guid VerificationFlowId { get; set; }

    public byte[]? SecureKey { get; set; }

    public byte[]? MaskingKey { get; set; } 

    public byte[]? Mac { get; set; } 

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "inactive";

    [MaxLength(20)]
    public string? CreationStatus { get; set; }

    [ForeignKey(nameof(MobileNumberId))]
    public virtual MobileNumber MobileNumber { get; set; } = null!;

    [ForeignKey(nameof(AppDeviceId))]
    public virtual Device AppDevice { get; set; } = null!;

    [ForeignKey(nameof(VerificationFlowId))]
    public virtual VerificationFlow VerificationFlow { get; set; } = null!;

    public virtual ICollection<MembershipAttempt> MembershipAttempts { get; set; } = new List<MembershipAttempt>();
    public virtual ICollection<LoginAttempt> LoginAttempts { get; set; } = new List<LoginAttempt>();
}