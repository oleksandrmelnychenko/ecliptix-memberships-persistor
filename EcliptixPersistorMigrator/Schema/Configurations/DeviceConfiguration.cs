using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EcliptixPersistorMigrator.Schema.Entities;

namespace EcliptixPersistorMigrator.Schema.Configurations;

public class DeviceConfiguration : IEntityTypeConfiguration<Device>
{
    public void Configure(EntityTypeBuilder<Device> builder)
    {
        builder.ToTable("Devices");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.AppInstanceId)
            .IsRequired();

        builder.Property(e => e.DeviceId)
            .IsRequired();

        builder.Property(e => e.DeviceType)
            .HasDefaultValue(1);

        builder.Property(e => e.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.UpdatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(e => e.UniqueId)
            .HasDefaultValueSql("NEWID()");

        builder.HasIndex(e => e.UniqueId)
            .IsUnique()
            .HasDatabaseName("UQ_Devices_UniqueId");

        builder.HasIndex(e => e.DeviceId)
            .IsUnique()
            .HasDatabaseName("UQ_Devices_DeviceId");

        builder.HasIndex(e => e.AppInstanceId)
            .HasDatabaseName("IX_Devices_AppInstanceId");

        builder.HasIndex(e => e.DeviceType)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_Devices_DeviceType");

        builder.HasIndex(e => e.CreatedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_Devices_CreatedAt");
    }
}