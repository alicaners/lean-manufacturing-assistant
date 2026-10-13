using System.Diagnostics;
using Serilog.Context;

namespace LeanAssistant.Api.Middleware;

/// <summary>
/// Gives every request a correlation id: taken from the X-Correlation-Id header
/// when the client sends a valid one, otherwise the W3C trace id.
/// The id is added to every log line and returned in the response header.
/// </summary>
public sealed class CorrelationIdMiddleware(RequestDelegate next)
{
    public const string HeaderName = "X-Correlation-Id";
    public const string ItemKey = "CorrelationId";
    private const int MaxLength = 64;

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = ResolveCorrelationId(context);

        context.Items[ItemKey] = correlationId;
        context.Response.OnStarting(() =>
        {
            context.Response.Headers[HeaderName] = correlationId;
            return Task.CompletedTask;
        });

        using (LogContext.PushProperty("CorrelationId", correlationId))
        {
            await next(context);
        }
    }

    private static string ResolveCorrelationId(HttpContext context)
    {
        var incoming = context.Request.Headers[HeaderName].ToString();

        if (IsValid(incoming))
        {
            return incoming;
        }

        return Activity.Current?.TraceId.ToString() ?? Guid.NewGuid().ToString("N");
    }

    private static bool IsValid(string value) =>
        value.Length is > 0 and <= MaxLength
        && value.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_');
}