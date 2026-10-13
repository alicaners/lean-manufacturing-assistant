using LeanAssistant.Infrastructure.Logging;
using Serilog.Events;
using Serilog.Parsing;

namespace LeanAssistant.UnitTests.Logging;

public class SensitiveDataEnricherTests
{
    private readonly SensitiveDataEnricher _enricher = new();

    [Fact]
    public void Sensitive_properties_are_masked_and_others_are_kept()
    {
        var logEvent = CreateEvent(
            new LogEventProperty("Password", new ScalarValue("hunter2")),
            new LogEventProperty("RefreshToken", new ScalarValue("abc.def.ghi")),
            new LogEventProperty("UserName", new ScalarValue("ali")));

        _enricher.Enrich(logEvent, null!);

        Assert.Equal(SensitiveDataEnricher.Mask, ScalarOf(logEvent, "Password"));
        Assert.Equal(SensitiveDataEnricher.Mask, ScalarOf(logEvent, "RefreshToken"));
        Assert.Equal("ali", ScalarOf(logEvent, "UserName"));
    }

    [Fact]
    public void Sensitive_properties_inside_objects_are_masked()
    {
        var request = new StructureValue(
        [
            new LogEventProperty("Email", new ScalarValue("ali@example.com")),
            new LogEventProperty("Password", new ScalarValue("hunter2"))
        ]);
        var logEvent = CreateEvent(new LogEventProperty("Request", request));

        _enricher.Enrich(logEvent, null!);

        var masked = (StructureValue)logEvent.Properties["Request"];
        var password = (ScalarValue)masked.Properties.Single(p => p.Name == "Password").Value;
        var email = (ScalarValue)masked.Properties.Single(p => p.Name == "Email").Value;

        Assert.Equal(SensitiveDataEnricher.Mask, password.Value);
        Assert.Equal("ali@example.com", email.Value);
    }

    private static LogEvent CreateEvent(params LogEventProperty[] properties) =>
        new(
            DateTimeOffset.UnixEpoch,
            LogEventLevel.Information,
            exception: null,
            new MessageTemplateParser().Parse("test"),
            properties);

    private static object? ScalarOf(LogEvent logEvent, string name) =>
        ((ScalarValue)logEvent.Properties[name]).Value;
}