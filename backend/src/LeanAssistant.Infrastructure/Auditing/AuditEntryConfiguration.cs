using LeanAssistant.Domain.Auditing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Auditing;

internal sealed class AuditEntryConfiguration : IEntityTypeConfiguration<AuditEntry>
{
    public void Configure(EntityTypeBuilder<AuditEntry> builder)
    {
        builder.ToTable("AuditEntries");

        builder.Property(entry => entry.EntityType)
            .HasMaxLength(AuditEntry.EntityTypeMaxLength)
            .IsRequired();

        builder.Property(entry => entry.Action)
            .HasConversion<string>()
            .HasMaxLength(16);

        // PostgreSQL's binary JSON type: stored compactly and searchable.
        builder.Property(entry => entry.Changes)
            .HasColumnType("jsonb")
            .IsRequired();

        // The history of one record (e.g. a suggestion's timeline) is read by its id.
        builder.HasIndex(entry => new { entry.EntityType, entry.EntityId });

        builder.HasIndex(entry => entry.FactoryId);
    }
}