using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class LoginAttemptConfiguration : EntityBaseMap<LoginAttempt>
{
    public override void Map(EntityTypeBuilder<LoginAttempt> builder)
    {
        base.Map(builder);
        
        builder.ToTable("LoginAttempts");

        builder.Property(e => e.MembershipUniqueId)
            .IsRequired();

        builder.Property(e => e.MobileNumber)
            .HasMaxLength(18);

        builder.Property(e => e.Outcome)
            .HasMaxLength(500);

        builder.Property(e => e.IsSuccess)
            .HasDefaultValue(false);

        builder.Property(e => e.Timestamp)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Property(e => e.Status)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(e => e.ErrorMessage)
            .HasMaxLength(500);

        builder.Property(e => e.SessionId)
            .HasMaxLength(100);

        builder.Property(e => e.AttemptedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(e => e.MembershipUniqueId)
            .HasDatabaseName("IX_LoginAttempts_MembershipUniqueId");

        builder.HasIndex(e => e.AttemptedAt)
            .IsDescending()
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_LoginAttempts_AttemptedAt");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_LoginAttempts_Status");

        builder.HasIndex(e => e.SessionId)
            .HasFilter("IsDeleted = 0 AND SessionId IS NOT NULL")
            .HasDatabaseName("IX_LoginAttempts_SessionId");

        builder.HasIndex(e => e.MobileNumber)
            .HasFilter("IsDeleted = 0 AND MobileNumber IS NOT NULL")
            .HasDatabaseName("IX_LoginAttempts_MobileNumber");

        builder.HasIndex(e => e.Outcome)
            .HasFilter("IsDeleted = 0 AND Outcome IS NOT NULL")
            .HasDatabaseName("IX_LoginAttempts_Outcome");

        builder.HasIndex(e => e.Timestamp)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_LoginAttempts_Timestamp");

        builder.HasIndex(e => e.IsSuccess)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_LoginAttempts_IsSuccess");

        builder.HasOne(e => e.Membership)
            .WithMany(m => m.LoginAttempts)
            .HasForeignKey(e => e.MembershipUniqueId)
            .HasPrincipalKey(m => m.UniqueId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_LoginAttempts_Memberships");
    }
}