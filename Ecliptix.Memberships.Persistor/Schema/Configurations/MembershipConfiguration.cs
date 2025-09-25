using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class MembershipConfiguration : EntityBaseMap<Membership>
{
    public override void Map(EntityTypeBuilder<Membership> builder)
    {
        base.Map(builder);
        
        builder.ToTable("Memberships");

        builder.Property(e => e.MobileNumberId)
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

        builder.ToTable(t => t.HasCheckConstraint("CHK_Memberships_Status",
            "Status IN ('active', 'inactive')"));

        builder.ToTable(t => t.HasCheckConstraint("CHK_Memberships_CreationStatus",
            "CreationStatus IN ('otp_verified', 'secure_key_set', 'passphrase_set')"));

        builder.HasIndex(e => e.UniqueId)
            .IsUnique()
            .HasDatabaseName("UQ_Memberships_UniqueId");

        builder.HasIndex(e => new { e.MobileNumberId, e.AppDeviceId, e.IsDeleted })
            .IsUnique()
            .HasDatabaseName("UQ_Memberships_ActiveMembership");

        builder.HasIndex(e => e.MobileNumberId)
            .HasDatabaseName("IX_Memberships_MobileNumberId");

        builder.HasIndex(e => e.AppDeviceId)
            .HasDatabaseName("IX_Memberships_AppDeviceId");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_Memberships_Status");

        builder.HasOne(e => e.MobileNumber)
            .WithMany(p => p.Memberships)
            .HasForeignKey(e => e.MobileNumberId)
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