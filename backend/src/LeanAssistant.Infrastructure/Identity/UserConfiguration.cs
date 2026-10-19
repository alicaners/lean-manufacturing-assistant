using LeanAssistant.Domain.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Identity;

internal sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");

        builder.Property(user => user.UserName)
            .HasMaxLength(User.UserNameMaxLength)
            .IsRequired();

        // A deleted user's name can be given to someone new.
        builder.HasIndex(user => user.UserName)
            .IsUnique()
            .HasFilter("\"IsDeleted\" = false");

        builder.Property(user => user.FullName)
            .HasMaxLength(User.FullNameMaxLength)
            .IsRequired();

        builder.Property(user => user.PasswordHash)
            .HasMaxLength(256)
            .IsRequired();

        // Stored as text ("Supervisor"), not as a number.
        builder.Property(user => user.Role)
            .HasConversion<string>()
            .HasMaxLength(32)
            .IsRequired();

            
        // Every scoped query filters users by plant.
        builder.HasIndex(user => user.FactoryId);
    }
}