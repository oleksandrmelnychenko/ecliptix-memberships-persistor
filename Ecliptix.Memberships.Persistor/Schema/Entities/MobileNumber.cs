using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("MobileNumbers")]
public class MobileNumber
{
    [Key]
    public long Id { get; set; }

    [Required]
    [MaxLength(18)]
    public string PhoneNumber { get; set; } = string.Empty;

    [MaxLength(2)]
    public string? Region { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    public virtual ICollection<VerificationFlow> VerificationFlows { get; set; } = new List<VerificationFlow>();
    public virtual ICollection<Membership> Memberships { get; set; } = new List<Membership>();
    public virtual ICollection<MobileDevice> MobileDevices { get; set; } = new List<MobileDevice>();
}