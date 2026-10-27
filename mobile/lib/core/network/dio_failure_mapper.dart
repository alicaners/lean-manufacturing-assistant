import 'package:dio/dio.dart';
import 'package:lean_assistant/core/error/failure.dart';

/// Converts a [DioException] into a [Failure].
/// Reads the backend's ProblemDetails body (`errors`, `correlationId`).
Failure mapDioException(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      return _fromResponse(exception.response);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return UnknownFailure(error: exception);
  }
}

Failure _fromResponse(Response<Object?>? response) {
  final body = response?.data;
  final problem = body is Map<String, Object?>
      ? body
      : const <String, Object?>{};
  final id = problem['correlationId'];
  final correlationId = id is String ? id : null;

  return switch (response?.statusCode) {
    400 => ValidationFailure(
      fieldErrors: _parseFieldErrors(problem['errors']),
      correlationId: correlationId,
    ),
    401 => UnauthorizedFailure(correlationId: correlationId),
    403 => ForbiddenFailure(correlationId: correlationId),
    404 => NotFoundFailure(correlationId: correlationId),
    409 => ConflictFailure(correlationId: correlationId),
    429 => RateLimitedFailure(correlationId: correlationId),
    final int code when code >= 500 => ServerFailure(
      correlationId: correlationId,
    ),
    _ => UnknownFailure(correlationId: correlationId),
  };
}

Map<String, List<String>> _parseFieldErrors(Object? errors) {
  if (errors is! Map<String, Object?>) {
    return const {};
  }

  final result = <String, List<String>>{};
  for (final MapEntry(:key, :value) in errors.entries) {
    if (value is List<Object?>) {
      result[key] = value.whereType<String>().toList();
    }
  }
  return result;
}
