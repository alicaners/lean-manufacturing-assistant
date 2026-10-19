namespace LeanAssistant.Api.Identity;

/// <summary>
/// Keeps an endpoint open for a user who must change their password.
/// Every other endpoint answers 403 to such a user.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class AllowDuringPasswordChangeAttribute : Attribute;