using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class DeviceConfiguration : EntityBaseMap<Device>
{
    public override void Map(EntityTypeBuilder<Device> builder)
    {
        base.Map(builder);
        
        builder.ToTable("Devices");

        builder.Property(e => e.AppInstanceId)
            .IsRequired();

        builder.Property(e => e.DeviceId)
            .IsRequired();

        builder.Property(e => e.DeviceType)
            .HasDefaultValue(1);

        builder.HasIndex(e => e.DeviceId)
            .IsUnique()
            .HasDatabaseName("UQ_Devices_DeviceId");

        builder.HasIndex(e => e.AppInstanceId)
            .HasDatabaseName("IX_Devices_AppInstanceId");

        builder.HasIndex(e => e.DeviceType)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_Devices_DeviceType");
    }
}