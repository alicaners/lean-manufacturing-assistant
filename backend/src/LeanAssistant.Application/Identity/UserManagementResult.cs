using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public enum UserManagementError
{
    /// <summary>No such user, or the user is in another plant (we do not say which).</summary>
    NotFound,

    UserNameTaken,

    /// <summary>A plant admin tried to place a user in another plant.</summary>
    OutsideScope,

    /// <summary>Admins cannot lock themselves out by changing their own access.</summary>
    SelfChange
}

public sealed record UserManagementResult(UserManagementError? Error, UserResponse? Value)
{
    public bool Succeeded => Error is null;

    public static UserManagementResult Success(User? user = null) =>
        new(null, user is null ? null : UserResponse.From(user));

    public static UserManagementResult Failure(UserManagementError error) => new(error, null);
}