import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/network/dio_failure_mapper.dart';

DioException _badResponse(int statusCode, [Object? data]) {
  final options = RequestOptions(path: '/test');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  test('400 ProblemDetails becomes ValidationFailure with field errors', () {
    final failure = mapDioException(
      _badResponse(400, {
        'status': 400,
        'errors': {
          'Title': ["'Title' must not be empty."],
        },
        'correlationId': 'abc-123',
      }),
    );

    expect(failure, isA<ValidationFailure>());
    final validation = failure as ValidationFailure;
    expect(validation.fieldErrors['Title'], ["'Title' must not be empty."]);
    expect(validation.correlationId, 'abc-123');
  });

  test('409 becomes ConflictFailure', () {
    expect(mapDioException(_badResponse(409)), isA<ConflictFailure>());
  });

  test('5xx becomes ServerFailure', () {
    expect(mapDioException(_badResponse(503)), isA<ServerFailure>());
  });

  test('connection timeout becomes NetworkFailure', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(mapDioException(exception), isA<NetworkFailure>());
  });

  test('non-JSON error body does not crash', () {
    expect(
      mapDioException(_badResponse(404, '<html>Not Found</html>')),
      isA<NotFoundFailure>(),
    );
  });
}
