namespace LeanAssistant.Application.Abstractions;

/// <summary>
/// What other modules may ask about the organization tree without reading its tables.
/// Implemented by the Organization module.
/// </summary>
public interface IOrganizationDirectory
{
    /// <summary>
    /// True when the plant exists and, if a line is given, the line belongs to that plant.
    /// Answered within the caller's own plant scope.
    /// </summary>
    Task<bool> IsValidScopeAsync(Guid factoryId, Guid? lineId, CancellationToken cancellationToken);
}