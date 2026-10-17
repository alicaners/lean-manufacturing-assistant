using FluentValidation;

namespace LeanAssistant.Application.Identity;

/// <summary>Body of both the refresh and the logout requests.</summary>
public sealed record RefreshTokenRequest(string RefreshToken);

public sealed class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(request => request.RefreshToken)
            .NotEmpty()
            .MaximumLength(128);
    }
}