using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ecliptix.Memberships.Persistor.Schema.Entities;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class OtpCodeConfiguration : EntityBaseMap<OtpCode>
{
    public override void Map(EntityTypeBuilder<OtpCode> builder)
    {
        base.Map(builder);
        
        builder.ToTable("OtpCodes");

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

        builder.ToTable(t => t.HasCheckConstraint("CHK_OtpCodes_Status",
            "Status IN ('active', 'used', 'expired', 'invalid')"));

        builder.HasIndex(e => e.VerificationFlowId)
            .HasDatabaseName("IX_OtpCodes_VerificationFlowId");

        builder.HasIndex(e => e.Status)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_OtpCodes_Status");

        builder.HasIndex(e => e.ExpiresAt)
            .HasFilter("IsDeleted = 0")
            .HasDatabaseName("IX_OtpCodes_ExpiresAt");
        
        builder.HasOne(e => e.VerificationFlow)
            .WithMany(v => v.OtpCodes)
            .HasForeignKey(e => e.VerificationFlowId)
            .OnDelete(DeleteBehavior.Cascade)
            .HasConstraintName("FK_OtpCodes_VerificationFlows");
    }
}