using LeanAssistant.Domain.Organization;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Organization;

internal sealed class LineConfiguration : IEntityTypeConfiguration<Line>
{
    public void Configure(EntityTypeBuilder<Line> builder)
    {
        builder.ToTable("Lines");

        builder.Property(line => line.Name)
            .HasMaxLength(Line.NameMaxLength)
            .IsRequired();

        builder.HasOne<Factory>()
            .WithMany()
            .HasForeignKey(line => line.FactoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Department>()
            .WithMany()
            .HasForeignKey(line => line.DepartmentId)
            .OnDelete(DeleteBehavior.Restrict);

        // Two lines of the same department cannot share a name.
        builder.HasIndex(line => new { line.DepartmentId, line.Name })
            .IsUnique()
            .HasFilter("\"IsDeleted\" = false");
    }
}