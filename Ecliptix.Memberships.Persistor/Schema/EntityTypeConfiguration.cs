using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Ecliptix.Memberships.Persistor.Schema;

public abstract class EntityTypeConfiguration<TEntity> where TEntity : class
{
    public abstract void Map(EntityTypeBuilder<TEntity> builder);
}