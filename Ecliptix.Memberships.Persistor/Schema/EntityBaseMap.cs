using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Ecliptix.Memberships.Persistor.Schema;

public abstract class EntityBaseMap<T> : EntityTypeConfiguration<T> where T : EntityBase
{
    public override void Map(EntityTypeBuilder<T> entity)
    {
        entity.HasKey(e => e.Id);
        entity.Property(e => e.Id)
            .UseIdentityColumn();
        
        entity.Property(e => e.UniqueId)
            .HasDefaultValueSql("NEWID()");
        
        entity.Property(e => e.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");
        
        entity.Property(e => e.UpdatedAt)
            .HasDefaultValueSql("GETUTCDATE()");
        
        entity.Property(e => e.IsDeleted)
            .HasDefaultValue(false);
        
        entity.HasIndex(e => e.UniqueId).IsUnique();
    }
}