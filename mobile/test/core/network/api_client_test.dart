import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/core/network/correlation_id_interceptor.dart';

/// Returns a fixed response instead of doing real network I/O.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final String body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(CorrelationIdInterceptor());
  return ApiClient(dio);
}

String _parseStatus(Object? json) =>
    (json! as Map<String, Object?>)['status']! as String;

void main() {
  test('returns Ok with the parsed body and sends a correlation id', () async {
    final adapter = _FakeAdapter(200, '{"status":"Healthy"}');

    final result = await _client(adapter).get('/health', parse: _parseStatus);

    expect(result, isA<Ok<String>>());
    expect((result as Ok<String>).value, 'Healthy');
    expect(
      adapter.lastRequest?.headers[CorrelationIdInterceptor.headerName],
      isNotNull,
    );
  });

  test('returns Err with ConflictFailure on 409', () async {
    final adapter = _FakeAdapter(
      409,
      '{"status":409,"correlationId":"abc-123"}',
    );

    final result = await _client(adapter)
        .get('/downtimes/1', parse: _parseStatus);

    expect(result, isA<Err<String>>());
    final failure = (result as Err<String>).failure;
    expect(failure, isA<ConflictFailure>());
    expect(failure.correlationId, 'abc-123');
  });

  test(
    'returns Err with UnknownFailure when the body has an unexpected shape',
    () async {
      final adapter = _FakeAdapter(200, '{"unexpected":true}');

      final result = await _client(adapter).get('/health', parse: _parseStatus);

      expect((result as Err<String>).failure, isA<UnknownFailure>());
    },
  );
}
