using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EcliptixPersistorMigrator.Schema.Entities;

[Table("Memberships")]
public class Membership
{
    [Key]
    public long Id { get; set; }

    [Required]
    public Guid PhoneNumberId { get; set; }

    [Required]
    public Guid AppDeviceId { get; set; }

    [Required]
    public Guid VerificationFlowId { get; set; }

    public byte[]? SecureKey { get; set; }

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "inactive";

    [MaxLength(20)]
    public string? CreationStatus { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    [ForeignKey(nameof(PhoneNumberId))]
    public virtual MobileNumber PhoneNumber { get; set; } = null!;

    [ForeignKey(nameof(AppDeviceId))]
    public virtual Device AppDevice { get; set; } = null!;

    [ForeignKey(nameof(VerificationFlowId))]
    public virtual VerificationFlow VerificationFlow { get; set; } = null!;

    public virtual ICollection<MembershipAttempt> MembershipAttempts { get; set; } = new List<MembershipAttempt>();
    public virtual ICollection<LoginAttempt> LoginAttempts { get; set; } = new List<LoginAttempt>();
}