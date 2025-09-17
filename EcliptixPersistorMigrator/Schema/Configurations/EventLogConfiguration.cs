using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EcliptixPersistorMigrator.Schema.Entities;

namespace EcliptixPersistorMigrator.Schema.Configurations;

public class EventLogConfiguration : IEntityTypeConfiguration<EventLog>
{
    public void Configure(EntityTypeBuilder<EventLog> builder)
    {
        builder.ToTable("EventLogs");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

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

        builder.Property(e => e.IpAddress)
            .HasMaxLength(45);

        builder.Property(e => e.UserAgent)
            .HasMaxLength(500);

        builder.Property(e => e.SessionId)
            .HasMaxLength(100);

        builder.Property(e => e.OccurredAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.UpdatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(e => e.UniqueId)
            .HasDefaultValueSql("NEWID()");

        // Indexes
        builder.HasIndex(e => e.UniqueId)
            .IsUnique()
            .HasDatabaseName("UQ_EventLogs_UniqueId");

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