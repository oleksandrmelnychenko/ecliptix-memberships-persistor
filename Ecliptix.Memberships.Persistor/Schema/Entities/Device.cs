using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("Devices")]
public class Device : EntityBase
{
    [Required]
    public Guid AppInstanceId { get; set; }

    [Required]
    public Guid DeviceId { get; set; }

    public int DeviceType { get; set; } = 1;

    public virtual ICollection<VerificationFlow> VerificationFlows { get; set; } = new List<VerificationFlow>();
    public virtual ICollection<Membership> Memberships { get; set; } = new List<Membership>();
    public virtual ICollection<MobileDevice> MobileDevices { get; set; } = new List<MobileDevice>();
}