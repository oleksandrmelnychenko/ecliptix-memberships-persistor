using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

[Table("MobileDevices")]
public class MobileDevice : EntityBase
{
    [Required]
    public long MobileNumberId { get; set; }

    [Required]
    public long DeviceId { get; set; }

    [MaxLength(50)]
    public string? RelationshipType { get; set; } = "primary";

    public bool IsActive { get; set; } = true;

    public DateTime? LastUsedAt { get; set; }

    [ForeignKey(nameof(MobileNumberId))]
    public virtual MobileNumber MobileNumber { get; set; } = null!;

    [ForeignKey(nameof(DeviceId))]
    public virtual Device Device { get; set; } = null!;
}