using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class MobileNumberConfiguration : IEntityTypeConfiguration<MobileNumber>
{
    public void Configure(EntityTypeBuilder<MobileNumber> builder)
    {
        builder.ToTable("MobileNumbers");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.Number)
            .IsRequired()
            .HasMaxLength(18);

        builder.Property(e => e.Region)
            .HasMaxLength(2);

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
            .HasDatabaseName("UQ_MobileNumbers_UniqueId");

        builder.HasIndex(e => new { e.Number, e.Region, e.IsDeleted })
            .IsUnique()
            .HasDatabaseName("UQ_MobileNumbers_ActiveNumberRegion");

        builder.HasIndex(e => new { e.Number, e.Region })
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_MobileNumbers_MobileNumber_Region");

        builder.HasIndex(e => e.Region)
            .HasFilter("IsDeleted = 0 AND Region IS NOT NULL")
            .HasDatabaseName("IX_MobileNumbers_Region");

        builder.HasIndex(e => e.CreatedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_MobileNumbers_CreatedAt");
    }
}