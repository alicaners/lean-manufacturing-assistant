import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/config/app_config.dart';
import 'package:lean_assistant/core/network/correlation_id_interceptor.dart';
import 'package:lean_assistant/core/network/dio_names.dart';
import 'package:lean_assistant/features/auth/data/auth_interceptor.dart';

@module
abstract class NetworkModule {
  /// The Dio every repository uses: adds the access token and renews it on 401.
  @lazySingleton
  Dio dio(AppConfig config, AuthInterceptor authInterceptor) =>
      _createDio(config, auth: authInterceptor);

  /// Sends token refreshes and retries. It has no AuthInterceptor,
  /// so a refresh can never start another refresh.
  @Named(refreshDioName)
  @lazySingleton
  Dio refreshDio(AppConfig config) => _createDio(config);
}

Dio _createDio(AppConfig config, {Interceptor? auth}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(CorrelationIdInterceptor());

  if (auth != null) {
    dio.interceptors.add(auth);
  }

  if (kDebugMode) {
    // Method, URL and status only: never log headers or bodies,
    // they may contain tokens and passwords.
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  return dio;
}
