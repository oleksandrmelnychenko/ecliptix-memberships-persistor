using System.ComponentModel.DataAnnotations;

namespace Ecliptix.Memberships.Persistor.Schema.Entities;

public class EventLog : EntityBase
{
    public string EventType { get; set; } = string.Empty;

    public string Severity { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public string? Details { get; set; }

    public string? EntityType { get; set; }

    public long? EntityId { get; set; }

    public Guid? UserId { get; set; }

    public string? SessionId { get; set; }

    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
}