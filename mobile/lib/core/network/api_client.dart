import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/dio_failure_mapper.dart';

/// Converts JSON into a model. Throws [FormatException] or [TypeError]
/// if the JSON does not have the expected shape.
typedef JsonParser<T> = T Function(Object? json);

/// The only place that talks HTTP. Every call returns a [Result],
/// so callers never need try/catch.
@lazySingleton
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Result<T>> get<T>(
    String path, {
    required JsonParser<T> parse,
    Map<String, Object?>? query,
  }) {
    return _send(() => _dio.get<Object?>(path, queryParameters: query), parse);
  }

  Future<Result<T>> post<T>(
    String path, {
    required JsonParser<T> parse,
    Object? body,
  }) {
    return _send(() => _dio.post<Object?>(path, data: body), parse);
  }

  Future<Result<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    JsonParser<T> parse,
  ) async {
    try {
      final response = await request();
      return Ok(parse(response.data));
    } on DioException catch (exception) {
      return Err(mapDioException(exception));
    } on FormatException catch (exception) {
      return Err(UnknownFailure(error: exception));
    } on TypeError catch (exception) {
      return Err(UnknownFailure(error: exception));
    }
  }
}
