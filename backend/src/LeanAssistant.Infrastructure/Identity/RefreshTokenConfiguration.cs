using LeanAssistant.Domain.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Identity;

internal sealed class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    // SHA-256 written as hexadecimal text is always 64 characters.
    private const int TokenHashLength = 64;

    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("RefreshTokens");

        builder.Property(token => token.TokenHash)
            .HasMaxLength(TokenHashLength)
            .IsFixedLength()
            .IsRequired();

        // Every refresh request looks a token up by its hash.
        builder.HasIndex(token => token.TokenHash)
            .IsUnique();

        // Reuse detection revokes a whole family at once.
        builder.HasIndex(token => token.FamilyId);

        builder.Property(token => token.RevocationReason)
            .HasConversion<string>()
            .HasMaxLength(32);

        // Users are never hard-deleted, so their tokens must not be either.
        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(token => token.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}