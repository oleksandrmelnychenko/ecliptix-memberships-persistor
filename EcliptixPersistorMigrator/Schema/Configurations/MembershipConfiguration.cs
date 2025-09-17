using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EcliptixPersistorMigrator.Schema.Entities;

namespace EcliptixPersistorMigrator.Schema.Configurations;

public class MembershipConfiguration : IEntityTypeConfiguration<Membership>
{
    public void Configure(EntityTypeBuilder<Membership> builder)
    {
        builder.ToTable("Memberships");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.PhoneNumberId)
            .IsRequired();

        builder.Property(e => e.AppDeviceId)
            .IsRequired();

        builder.Property(e => e.VerificationFlowId)
            .IsRequired();

        builder.Property(e => e.SecureKey)
            .HasColumnType("VARBINARY(MAX)");

        builder.Property(e => e.Status)
            .IsRequired()
            .HasMaxLength(20)
            .HasDefaultValue("inactive");

        builder.Property(e => e.CreationStatus)
            .HasMaxLength(20);

        builder.Property(e => e.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.UpdatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(e => e.UniqueId)
            .HasDefaultValueSql("NEWID()");

        // Check constraints
        builder.ToTable(t => t.HasCheckConstraint("CHK_Memberships_Status",
            "Status IN ('active', 'inactive')"));

        builder.ToTable(t => t.HasCheckConstraint("CHK_Memberships_CreationStatus",
            "CreationStatus IN ('otp_verified', 'secure_key_set', 'passphrase_set')"));

        // Indexes
        builder.HasIndex(e => e.UniqueId)
            .IsUnique()
            .HasDatabaseName("UQ_Memberships_UniqueId");

        builder.HasIndex(e => new { e.PhoneNumberId, e.AppDeviceId, e.IsDeleted })
            .IsUnique()
            .HasDatabaseName("UQ_Memberships_ActiveMembership");

        builder.HasIndex(e => e.PhoneNumberId)
            .HasDatabaseName("IX_Memberships_PhoneNumberId");

        builder.HasIndex(e => e.AppDeviceId)
            .HasDatabaseName("IX_Memberships_AppDeviceId");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_Memberships_Status");

        // Foreign Key Relationships
        builder.HasOne(e => e.PhoneNumber)
            .WithMany(p => p.Memberships)
            .HasForeignKey(e => e.PhoneNumberId)
            .HasPrincipalKey(p => p.UniqueId)
            .OnDelete(DeleteBehavior.NoAction)
            .HasConstraintName("FK_Memberships_MobileNumbers");

        builder.HasOne(e => e.AppDevice)
            .WithMany(d => d.Memberships)
            .HasForeignKey(e => e.AppDeviceId)
            .HasPrincipalKey(d => d.UniqueId)
            .OnDelete(DeleteBehavior.NoAction)
            .HasConstraintName("FK_Memberships_Devices");

        builder.HasOne(e => e.VerificationFlow)
            .WithMany(v => v.Memberships)
            .HasForeignKey(e => e.VerificationFlowId)
            .HasPrincipalKey(v => v.UniqueId)
            .OnDelete(DeleteBehavior.NoAction)
            .HasConstraintName("FK_Memberships_VerificationFlows");
    }
}