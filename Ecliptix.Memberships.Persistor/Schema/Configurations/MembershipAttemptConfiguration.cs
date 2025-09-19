using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class MembershipAttemptConfiguration : IEntityTypeConfiguration<MembershipAttempt>
{
    public void Configure(EntityTypeBuilder<MembershipAttempt> builder)
    {
        builder.ToTable("MembershipAttempts");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .UseIdentityColumn();

        builder.Property(e => e.MembershipId)
            .IsRequired();

        builder.Property(e => e.AttemptType)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(e => e.Status)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(e => e.ErrorMessage)
            .HasMaxLength(500);

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
            .HasDatabaseName("UQ_MembershipAttempts_UniqueId");

        builder.HasIndex(e => e.MembershipId)
            .HasDatabaseName("IX_MembershipAttempts_MembershipId");

        builder.HasIndex(e => e.AttemptedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_MembershipAttempts_AttemptedAt");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_MembershipAttempts_Status");

        builder.HasIndex(e => e.IpAddress)
            .HasFilter("IsDeleted = 0 AND IpAddress IS NOT NULL")
            .HasDatabaseName("IX_MembershipAttempts_IpAddress");

        builder.HasOne(e => e.Membership)
            .WithMany(m => m.MembershipAttempts)
            .HasForeignKey(e => e.MembershipId)
            .HasPrincipalKey(m => m.UniqueId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_MembershipAttempts_Memberships");
    }
}