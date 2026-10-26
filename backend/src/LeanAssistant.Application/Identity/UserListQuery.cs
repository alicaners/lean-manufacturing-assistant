using FluentValidation;
using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

/// <summary>Query string of <c>GET /api/users</c>. Every filter is optional.</summary>
public sealed class UserListQuery
{
    /// <summary>Part of the user name or the full name. Case does not matter.</summary>
    public string? Search { get; init; }

    public Role? Role { get; init; }

    public bool? IsActive { get; init; }

    /// <summary>The <c>nextCursor</c> of the previous page; empty for the first page.</summary>
    public string? Cursor { get; init; }

    public int Limit { get; init; } = Paging.DefaultLimit;
}

/// <summary>Where the previous page ended. Users are listed by user name, which is unique.</summary>
public sealed record UserListPosition(string UserName);

/// <summary>The filters, passed to the repository without paging details.</summary>
public sealed record UserFilter(string? Search, Role? Role, bool? IsActive);

public sealed class UserListQueryValidator : AbstractValidator<UserListQuery>
{
    public UserListQueryValidator()
    {
        RuleFor(query => query.Search)
            .MaximumLength(User.FullNameMaxLength);

        RuleFor(query => query.Role)
            .IsInEnum();

        RuleFor(query => query.Limit)
            .InclusiveBetween(1, Paging.MaxLimit);

        RuleFor(query => query.Cursor)
            .Must(cursor => Abstractions.Cursor.TryDecode<UserListPosition>(cursor, out _))
            .When(query => query.Cursor is not null)
            .WithMessage("The cursor is not valid. Request the first page again without a cursor.");
    }
}