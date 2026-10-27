// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:lean_assistant/app/di/app_module.dart' as _i637;
import 'package:lean_assistant/core/config/app_config.dart' as _i345;
import 'package:lean_assistant/core/network/api_client.dart' as _i150;
import 'package:lean_assistant/core/network/network_module.dart' as _i49;
import 'package:lean_assistant/core/storage/storage_module.dart' as _i743;
import 'package:lean_assistant/features/auth/data/api_auth_repository.dart'
    as _i223;
import 'package:lean_assistant/features/auth/data/auth_interceptor.dart'
    as _i636;
import 'package:lean_assistant/features/auth/data/session_refresher.dart'
    as _i387;
import 'package:lean_assistant/features/auth/data/session_store.dart' as _i274;
import 'package:lean_assistant/features/auth/domain/auth_repository.dart'
    as _i924;
import 'package:lean_assistant/features/dashboard/data/api_health_repository.dart'
    as _i663;
import 'package:lean_assistant/features/dashboard/domain/health_repository.dart'
    as _i327;
import 'package:lean_assistant/features/dashboard/presentation/server_status_cubit.dart'
    as _i168;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    final storageModule = _$StorageModule();
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i583.GoRouter>(() => appModule.router);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => storageModule.secureStorage,
    );
    gh.lazySingleton<_i274.SessionStore>(
      () => _i274.SecureSessionStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.refreshDio(gh<_i345.AppConfig>()),
      instanceName: 'refreshDio',
    );
    gh.lazySingleton<_i387.SessionRefresher>(
      () => _i387.SessionRefresher(
        gh<_i361.Dio>(instanceName: 'refreshDio'),
        gh<_i274.SessionStore>(),
      ),
    );
    gh.lazySingleton<_i636.AuthInterceptor>(
      () => _i636.AuthInterceptor(
        gh<_i274.SessionStore>(),
        gh<_i387.SessionRefresher>(),
        gh<_i361.Dio>(instanceName: 'refreshDio'),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () =>
          networkModule.dio(gh<_i345.AppConfig>(), gh<_i636.AuthInterceptor>()),
    );
    gh.lazySingleton<_i150.ApiClient>(() => _i150.ApiClient(gh<_i361.Dio>()));
    gh.lazySingleton<_i924.AuthRepository>(
      () => _i223.ApiAuthRepository(
        gh<_i150.ApiClient>(),
        gh<_i274.SessionStore>(),
        gh<_i387.SessionRefresher>(),
      ),
    );
    gh.lazySingleton<_i327.HealthRepository>(
      () => _i663.ApiHealthRepository(gh<_i150.ApiClient>()),
    );
    gh.factory<_i168.ServerStatusCubit>(
      () => _i168.ServerStatusCubit(gh<_i327.HealthRepository>()),
    );
    return this;
  }
}

class _$AppModule extends _i637.AppModule {}

class _$StorageModule extends _i743.StorageModule {}

class _$NetworkModule extends _i49.NetworkModule {}
