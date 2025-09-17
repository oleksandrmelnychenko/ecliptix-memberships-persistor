using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EcliptixPersistorMigrator.Schema.Entities;

[Table("EventLogs")]
public class EventLog
{
    [Key]
    public long Id { get; set; }

    [Required]
    [MaxLength(50)]
    public string EventType { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Severity { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Message { get; set; } = string.Empty;

    [MaxLength(4000)]
    public string? Details { get; set; }

    [MaxLength(100)]
    public string? EntityType { get; set; }

    public long? EntityId { get; set; }

    public Guid? UserId { get; set; }

    [MaxLength(45)]
    public string? IpAddress { get; set; }

    [MaxLength(500)]
    public string? UserAgent { get; set; }

    [MaxLength(100)]
    public string? SessionId { get; set; }

    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; } = false;

    public Guid UniqueId { get; set; } = Guid.NewGuid();
}