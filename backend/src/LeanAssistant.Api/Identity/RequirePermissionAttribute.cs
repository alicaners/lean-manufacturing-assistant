using LeanAssistant.Domain.Identity;
using Microsoft.AspNetCore.Authorization;

namespace LeanAssistant.Api.Identity;

/// <summary>
/// Allows the endpoint only for roles that hold the permission
/// (see <see cref="RolePermissions"/>). Missing permission → 403 Forbidden.
/// </summary>
public sealed class RequirePermissionAttribute(Permission permission)
    : AuthorizeAttribute(permission.ToString());