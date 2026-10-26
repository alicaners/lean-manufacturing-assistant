namespace LeanAssistant.Domain.SharedKernel;

/// <summary>
/// Every change to an entity with this marker is written to the audit log automatically:
/// who, when, which record, old and new values.
/// </summary>
public interface IAudited;