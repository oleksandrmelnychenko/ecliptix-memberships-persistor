using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("MobileNumbers")]
public class MobileNumber : EntityBase
{
    [Required]
    [MaxLength(18)]
    public string Number { get; set; } = string.Empty;

    [MaxLength(2)]
    public string? Region { get; set; }

    public virtual ICollection<VerificationFlow> VerificationFlows { get; set; } = new List<VerificationFlow>();
    public virtual ICollection<Membership> Memberships { get; set; } = new List<Membership>();
    public virtual ICollection<MobileDevice> MobileDevices { get; set; } = new List<MobileDevice>();
}