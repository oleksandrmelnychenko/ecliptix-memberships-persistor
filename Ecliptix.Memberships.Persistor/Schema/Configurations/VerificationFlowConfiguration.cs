using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class VerificationFlowConfiguration : IEntityTypeConfiguration<VerificationFlow>
{
    public void Configure(EntityTypeBuilder<VerificationFlow> builder)
    {
        builder.ToTable("VerificationFlows");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.MobileNumberId)
            .IsRequired();

        builder.Property(e => e.AppDeviceId)
            .IsRequired();

        builder.Property(e => e.Status)
            .IsRequired()
            .HasMaxLength(20)
            .HasDefaultValue("pending");

        builder.Property(e => e.Purpose)
            .IsRequired()
            .HasMaxLength(30)
            .HasDefaultValue("unspecified");

        builder.Property(e => e.ExpiresAt)
            .IsRequired();

        builder.Property(e => e.OtpCount)
            .HasDefaultValue((short)0);

        builder.Property(e => e.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.UpdatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(e => e.UniqueId)
            .HasDefaultValueSql("NEWID()");

        builder.ToTable(t => t.HasCheckConstraint("CHK_VerificationFlows_Status",
            "Status IN ('pending', 'verified', 'expired', 'failed')"));

        builder.ToTable(t => t.HasCheckConstraint("CHK_VerificationFlows_Purpose",
            "Purpose IN ('unspecified', 'registration', 'login', 'password_recovery', 'update_phone')"));

        builder.HasIndex(e => e.UniqueId)
            .IsUnique()
            .HasDatabaseName("UQ_VerificationFlows_UniqueId");

        builder.HasIndex(e => e.MobileNumberId)
            .HasDatabaseName("IX_VerificationFlows_MobileNumberId");

        builder.HasIndex(e => e.AppDeviceId)
            .HasDatabaseName("IX_VerificationFlows_AppDeviceId");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_VerificationFlows_Status");

        builder.HasIndex(e => e.ExpiresAt)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_VerificationFlows_ExpiresAt");

        builder.HasOne(e => e.MobileNumber)
            .WithMany(p => p.VerificationFlows)
            .HasForeignKey(e => e.MobileNumberId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_VerificationFlows_MobileNumbers");

        builder.HasOne(e => e.AppDevice)
            .WithMany(d => d.VerificationFlows)
            .HasForeignKey(e => e.AppDeviceId)
            .HasPrincipalKey(d => d.UniqueId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_VerificationFlows_Devices");
    }
}