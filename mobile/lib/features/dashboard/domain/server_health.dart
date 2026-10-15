/// Health of the backend as reported by `GET /health`.
///
/// ASP.NET Core answers "Healthy" or "Degraded" with HTTP 200.
/// "Unhealthy" comes with HTTP 503, so it arrives as a ServerFailure
/// through ApiClient and never reaches [parse].
enum ServerHealth {
  healthy,
  degraded;

  /// Converts the plain-text body of `/health` into a [ServerHealth].
  /// Throws [FormatException] for anything else; ApiClient turns that
  /// into an UnknownFailure.
  static ServerHealth parse(Object? body) {
    return switch (body) {
      'Healthy' => ServerHealth.healthy,
      'Degraded' => ServerHealth.degraded,
      _ => throw FormatException('Unexpected health status: $body'),
    };
  }
}
