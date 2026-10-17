using FluentValidation;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public sealed record LoginRequest(string UserName, string Password);

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    /// <summary>
    /// Long enough for any real password, short enough that huge inputs
    /// cannot keep the server busy with slow hashing.
    /// </summary>
    public const int PasswordMaxLength = 128;

    public LoginRequestValidator()
    {
        RuleFor(request => request.UserName)
            .NotEmpty()
            .MaximumLength(User.UserNameMaxLength);

        RuleFor(request => request.Password)
            .NotEmpty()
            .MaximumLength(PasswordMaxLength);
    }
}