namespace LeanAssistant.Application.Organization;

public enum OrganizationError
{
    /// <summary>No such record, or it belongs to another plant (we do not say which).</summary>
    NotFound,

    /// <summary>A plant code, or a machine code within a plant, is already in use.</summary>
    DuplicateCode,

    /// <summary>A department or line name is already in use under the same parent.</summary>
    DuplicateName,

    /// <summary>Only an admin without a plant (system admin) can create plants.</summary>
    SystemAdminOnly
}

/// <summary>Either a value or the reason there is none.</summary>
public sealed record OrganizationResult<T>(OrganizationError? Error, T? Value)
    where T : class
{
    public static implicit operator OrganizationResult<T>(T value) => new(null, value);

    public static implicit operator OrganizationResult<T>(OrganizationError error) => new(error, null);
}