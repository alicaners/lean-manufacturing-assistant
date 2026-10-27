/// Everything that can go wrong when talking to the backend.
///
/// The class is `sealed`: a `switch` over a [Failure] must handle every
/// subtype, so the compiler tells us when a case is forgotten.
sealed class Failure {
  const Failure({this.correlationId});

  /// Id of the request; can be used to find it in server logs and traces.
  final String? correlationId;
}

/// No connection, timeout or the server could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// 401: the session is missing or expired.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.correlationId});
}

/// 403: signed in, but not allowed to do this.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.correlationId});
}

/// 404: the record does not exist or is outside the user's scope.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.correlationId});
}

/// 409: someone else changed the record first (optimistic concurrency).
final class ConflictFailure extends Failure {
  const ConflictFailure({super.correlationId});
}

/// 400: input validation failed. [fieldErrors] maps field names to messages.
final class ValidationFailure extends Failure {
  const ValidationFailure({required this.fieldErrors, super.correlationId});

  final Map<String, List<String>> fieldErrors;
}

/// 429: too many attempts in a short time (e.g. sign-in).
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({super.correlationId});
}

/// 5xx: an unexpected error on the server.
final class ServerFailure extends Failure {
  const ServerFailure({super.correlationId});
}

/// Anything else (cancelled request, malformed response...).
final class UnknownFailure extends Failure {
  const UnknownFailure({this.error, super.correlationId});

  /// Original error, kept for logging and debugging.
  final Object? error;
}
