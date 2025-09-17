using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EcliptixPersistorMigrator.Schema.Entities;

[Table("MobileDevices")]
public class MobileDevice
{
    [Key]
    public long Id { get; set; }

    [Required]
    public long PhoneNumberId { get; set; }

    [Required]
    public long DeviceId { get; set; }

    [MaxLength(50)]
    public string? RelationshipType { get; set; } = "primary";

    public bool IsActive { get; set; } = true;

    public DateTime? LastUsedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();

    [ForeignKey(nameof(PhoneNumberId))]
    public virtual MobileNumber PhoneNumber { get; set; } = null!;

    [ForeignKey(nameof(DeviceId))]
    public virtual Device Device { get; set; } = null!;
}