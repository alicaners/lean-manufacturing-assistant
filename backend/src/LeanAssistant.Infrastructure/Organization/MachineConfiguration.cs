using LeanAssistant.Domain.Organization;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LeanAssistant.Infrastructure.Organization;

internal sealed class MachineConfiguration : IEntityTypeConfiguration<Machine>
{
    public void Configure(EntityTypeBuilder<Machine> builder)
    {
        builder.ToTable("Machines");

        builder.Property(machine => machine.Name)
            .HasMaxLength(Machine.NameMaxLength)
            .IsRequired();

        builder.Property(machine => machine.Code)
            .HasMaxLength(Machine.CodeMaxLength)
            .IsRequired();

        builder.Property(machine => machine.QrCode)
            .HasMaxLength(Machine.QrCodeLength)
            .IsFixedLength()
            .IsRequired();

        builder.HasOne<Factory>()
            .WithMany()
            .HasForeignKey(machine => machine.FactoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<Line>()
            .WithMany()
            .HasForeignKey(machine => machine.LineId)
            .OnDelete(DeleteBehavior.Restrict);

        // Asset numbers are unique within a plant.
        builder.HasIndex(machine => new { machine.FactoryId, machine.Code })
            .IsUnique()
            .HasFilter("\"IsDeleted\" = false");

        // Scanning a label looks the machine up by this value. No filter here:
        // a QR value is never reused, not even after the machine is deleted.
        builder.HasIndex(machine => machine.QrCode)
            .IsUnique();
    }
}