using Serilog.Core;
using Serilog.Events;

namespace LeanAssistant.Infrastructure.Logging;

/// <summary>
/// Masks log property values whose names look sensitive (passwords, tokens, secrets),
/// including properties nested inside destructured objects.
/// </summary>
public sealed class SensitiveDataEnricher : ILogEventEnricher
{
    public const string Mask = "***";

    private static readonly string[] SensitiveNameParts =
    [
        "password",
        "token",
        "secret",
        "authorization",
        "apikey",
        "connectionstring"
    ];

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        foreach (var (name, value) in logEvent.Properties.ToList())
        {
            var maskedValue = MaskIfSensitive(name, value);

            if (!ReferenceEquals(maskedValue, value))
            {
                logEvent.AddOrUpdateProperty(new LogEventProperty(name, maskedValue));
            }
        }
    }

    private static LogEventPropertyValue MaskIfSensitive(string name, LogEventPropertyValue value)
    {
        if (IsSensitive(name))
        {
            return new ScalarValue(Mask);
        }

        if (value is not StructureValue structure)
        {
            return value;
        }

        var changed = false;
        var properties = new List<LogEventProperty>();

        foreach (var property in structure.Properties)
        {
            var maskedValue = MaskIfSensitive(property.Name, property.Value);
            changed |= !ReferenceEquals(maskedValue, property.Value);
            properties.Add(new LogEventProperty(property.Name, maskedValue));
        }

        return changed ? new StructureValue(properties, structure.TypeTag) : value;
    }

    private static bool IsSensitive(string name) =>
        SensitiveNameParts.Any(part => name.Contains(part, StringComparison.OrdinalIgnoreCase));
}