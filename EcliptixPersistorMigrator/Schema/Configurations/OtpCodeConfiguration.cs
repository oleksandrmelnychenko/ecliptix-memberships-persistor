using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EcliptixPersistorMigrator.Schema.Entities;

namespace EcliptixPersistorMigrator.Schema.Configurations;

public class OtpCodeConfiguration : IEntityTypeConfiguration<OtpCode>
{
    public void Configure(EntityTypeBuilder<OtpCode> builder)
    {
        builder.ToTable("OtpCodes");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.VerificationFlowId)
            .IsRequired();

        builder.Property(e => e.OtpValue)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(e => e.Status)
            .IsRequired()
            .HasMaxLength(20)
            .HasDefaultValue("active");

        builder.Property(e => e.ExpiresAt)
            .IsRequired();

        builder.Property(e => e.AttemptCount)
            .HasDefaultValue((short)0);

        builder.Property(e => e.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.UpdatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(e => e.UniqueId)
            .HasDefaultValueSql("NEWID()");

        builder.ToTable(t => t.HasCheckConstraint("CHK_OtpCodes_Status",
            "Status IN ('active', 'used', 'expired', 'invalid')"));

        builder.HasIndex(e => e.UniqueId)
            .IsUnique()
            .HasDatabaseName("UQ_OtpCodes_UniqueId");

        builder.HasIndex(e => e.VerificationFlowId)
            .HasDatabaseName("IX_OtpCodes_VerificationFlowId");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_OtpCodes_Status");

        builder.HasIndex(e => e.ExpiresAt)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_OtpCodes_ExpiresAt");

        builder.HasIndex(e => e.CreatedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_OtpCodes_CreatedAt");

        builder.HasOne(e => e.VerificationFlow)
            .WithMany(v => v.OtpCodes)
            .HasForeignKey(e => e.VerificationFlowId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_OtpCodes_VerificationFlows");
    }
}