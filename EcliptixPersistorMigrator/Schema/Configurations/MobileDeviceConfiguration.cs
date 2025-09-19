using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EcliptixPersistorMigrator.Schema.Entities;

namespace EcliptixPersistorMigrator.Schema.Configurations;

public class MobileDeviceConfiguration : IEntityTypeConfiguration<MobileDevice>
{
    public void Configure(EntityTypeBuilder<MobileDevice> builder)
    {
        builder.ToTable("MobileDevices");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.PhoneNumberId)
            .IsRequired();

        builder.Property(e => e.DeviceId)
            .IsRequired();

        builder.Property(e => e.RelationshipType)
            .HasMaxLength(50)
            .HasDefaultValue("primary");

        builder.Property(e => e.IsActive)
            .HasDefaultValue(true);

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
            .HasDatabaseName("UQ_MobileDevices_UniqueId");

        builder.HasIndex(e => new { e.PhoneNumberId, e.DeviceId })
            .IsUnique()
            .HasDatabaseName("UQ_MobileDevices_PhoneDevice");

        builder.HasIndex(e => e.PhoneNumberId)
            .HasDatabaseName("IX_MobileDevices_PhoneNumberId");

        builder.HasIndex(e => e.DeviceId)
            .HasDatabaseName("IX_MobileDevices_DeviceId");

        builder.HasIndex(e => e.IsActive)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_MobileDevices_IsActive");

        builder.HasIndex(e => e.LastUsedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0 AND LastUsedAt IS NOT NULL")
            .HasDatabaseName("IX_MobileDevices_LastUsedAt");

        builder.HasOne(e => e.PhoneNumber)
            .WithMany(p => p.MobileDevices)
            .HasForeignKey(e => e.PhoneNumberId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_MobileDevices_MobileNumbers");

        builder.HasOne(e => e.Device)
            .WithMany(d => d.MobileDevices)
            .HasForeignKey(e => e.DeviceId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_MobileDevices_Devices");
    }
}