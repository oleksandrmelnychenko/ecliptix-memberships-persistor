using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using EcliptixPersistorMigrator.Schema.Entities;

namespace EcliptixPersistorMigrator.Schema.Configurations;

public class FailedOtpAttemptConfiguration : IEntityTypeConfiguration<FailedOtpAttempt>
{
    public void Configure(EntityTypeBuilder<FailedOtpAttempt> builder)
    {
        builder.ToTable("FailedOtpAttempts");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.OtpRecordId)
            .IsRequired();

        builder.Property(e => e.AttemptedValue)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(e => e.FailureReason)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(e => e.IpAddress)
            .HasMaxLength(45);

        builder.Property(e => e.UserAgent)
            .HasMaxLength(500);

        builder.Property(e => e.AttemptedAt)
            .HasDefaultValueSql("GETUTCDATE()");

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
            .HasDatabaseName("UQ_FailedOtpAttempts_UniqueId");

        builder.HasIndex(e => e.OtpRecordId)
            .HasDatabaseName("IX_FailedOtpAttempts_OtpRecordId");

        builder.HasIndex(e => e.AttemptedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_FailedOtpAttempts_AttemptedAt");

        builder.HasIndex(e => e.IpAddress)
            .HasFilter("IsDeleted = 0 AND IpAddress IS NOT NULL")
            .HasDatabaseName("IX_FailedOtpAttempts_IpAddress");

        builder.HasOne(e => e.OtpRecord)
            .WithMany(o => o.FailedAttempts)
            .HasForeignKey(e => e.OtpRecordId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_FailedOtpAttempts_OtpCodes");
    }
}