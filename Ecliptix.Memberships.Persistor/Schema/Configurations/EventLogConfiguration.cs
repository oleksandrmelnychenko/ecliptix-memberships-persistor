using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class EventLogConfiguration : EntityBaseMap<EventLog>
{
    public override void Map(EntityTypeBuilder<EventLog> builder)
    {
        base.Map(builder);
        
        builder.ToTable("EventLogs");

        builder.Property(e => e.EventType)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(e => e.Severity)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(e => e.Message)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(e => e.Details)
            .HasMaxLength(4000);

        builder.Property(e => e.EntityType)
            .HasMaxLength(100);

        builder.Property(e => e.SessionId)
            .HasMaxLength(100);

        builder.Property(e => e.OccurredAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(e => e.EventType)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_EventLogs_EventType");

        builder.HasIndex(e => e.Severity)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_EventLogs_Severity");

        builder.HasIndex(e => e.OccurredAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_EventLogs_OccurredAt");

        builder.HasIndex(e => new { e.EntityType, e.EntityId })
            .HasFilter("IsDeleted = 0 AND EntityType IS NOT NULL AND EntityId IS NOT NULL")
            .HasDatabaseName("IX_EventLogs_Entity");

        builder.HasIndex(e => e.UserId)
            .HasFilter("IsDeleted = 0 AND UserId IS NOT NULL")
            .HasDatabaseName("IX_EventLogs_UserId");

        builder.HasIndex(e => e.SessionId)
            .HasFilter("IsDeleted = 0 AND SessionId IS NOT NULL")
            .HasDatabaseName("IX_EventLogs_SessionId");
    }
}