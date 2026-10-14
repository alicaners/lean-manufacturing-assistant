import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Adds an `X-Correlation-Id` header to every request, so a request can be
/// traced from the phone to the server logs with a single id.
class CorrelationIdInterceptor extends Interceptor {
  CorrelationIdInterceptor({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String headerName = 'X-Correlation-Id';

  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(headerName, _uuid.v4);
    handler.next(options);
  }
}
