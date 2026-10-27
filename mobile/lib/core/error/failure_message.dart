import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';

/// User-facing, translated message for each kind of [Failure].
extension FailureMessage on Failure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      NetworkFailure() => l10n.errorNetwork,
      UnauthorizedFailure() => l10n.errorUnauthorized,
      ForbiddenFailure() => l10n.errorForbidden,
      NotFoundFailure() => l10n.errorNotFound,
      ConflictFailure() => l10n.errorConflict,
      ValidationFailure() => l10n.errorValidation,
      RateLimitedFailure() => l10n.errorRateLimited,
      ServerFailure() || UnknownFailure() => l10n.errorGenericMessage,
    };
  }
}
