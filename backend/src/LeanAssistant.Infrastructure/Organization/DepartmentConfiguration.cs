using LeanAssistant.Domain.Organization;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Organization;

internal sealed class DepartmentConfiguration : IEntityTypeConfiguration<Department>
{
    public void Configure(EntityTypeBuilder<Department> builder)
    {
        builder.ToTable("Departments");

        builder.Property(department => department.Name)
            .HasMaxLength(Department.NameMaxLength)
            .IsRequired();

        builder.HasOne<Factory>()
            .WithMany()
            .HasForeignKey(department => department.FactoryId)
            .OnDelete(DeleteBehavior.Restrict);

        // Two departments of the same plant cannot share a name.
        builder.HasIndex(department => new { department.FactoryId, department.Name })
            .IsUnique()
            .HasFilter("\"IsDeleted\" = false");
    }
}