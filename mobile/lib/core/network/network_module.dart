import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/config/app_config.dart';
import 'package:lean_assistant/core/network/correlation_id_interceptor.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(AppConfig config) {
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
}
