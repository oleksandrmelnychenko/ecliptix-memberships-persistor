using Ecliptix.Memberships.Persistor.Schema.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Ecliptix.Memberships.Persistor.Schema.Configurations;

public class MasterKeyShareConfiguration : EntityBaseMap<MasterKeyShare>
{
    public override void Map(EntityTypeBuilder<MasterKeyShare> builder)
    {
        base.Map(builder);

        builder.ToTable("MasterKeyShares");

        builder.Property(e => e.MembershipUniqueId)
            .IsRequired();
        
        builder.Property(e => e.ShareIndex)
            .IsRequired();
        
        builder.Property(e => e.EncryptedShare)
            .HasColumnType("VARBINARY(MAX)")
            .IsRequired();
        
        builder.Property(e => e.ShareMetadata)
            .HasColumnType("NVARCHAR(MAX)")
            .IsRequired();

        builder.Property(e => e.StorageLocation)
            .HasMaxLength(100)
            .IsRequired();
        
        builder.HasOne(e => e.Membership)
            .WithMany(m => m.MasterKeyShares)
            .HasForeignKey(e => e.MembershipUniqueId)
            .HasPrincipalKey(m => m.UniqueId)
            .OnDelete(DeleteBehavior.NoAction)
            .HasConstraintName("FK_MasterKeyShares_Memberships");
    }
}