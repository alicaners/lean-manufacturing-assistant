using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public interface IRefreshTokenRepository
{
    Task<RefreshToken?> FindByHashAsync(string tokenHash, CancellationToken cancellationToken);

    /// <summary>Tokens of the family that have not been revoked yet.</summary>
    Task<IReadOnlyList<RefreshToken>> ListActiveInFamilyAsync(
        Guid familyId, CancellationToken cancellationToken);

    void Add(RefreshToken token);
}