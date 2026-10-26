using LeanAssistant.Domain.Organization;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Organization;

internal sealed class FactoryConfiguration : IEntityTypeConfiguration<Factory>
{
    public void Configure(EntityTypeBuilder<Factory> builder)
    {
        builder.ToTable("Factories");

        builder.Property(factory => factory.Name)
            .HasMaxLength(Factory.NameMaxLength)
            .IsRequired();

        builder.Property(factory => factory.Code)
            .HasMaxLength(Factory.CodeMaxLength)
            .IsRequired();

        // Plant codes are unique across the system; a deleted plant's code can be reused.
        builder.HasIndex(factory => factory.Code)
            .IsUnique()
            .HasFilter("\"IsDeleted\" = false");
    }
}