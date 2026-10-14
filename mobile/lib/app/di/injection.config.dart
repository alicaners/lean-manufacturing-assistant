// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:lean_assistant/app/di/app_module.dart' as _i637;
import 'package:lean_assistant/core/config/app_config.dart' as _i345;
import 'package:lean_assistant/core/network/api_client.dart' as _i150;
import 'package:lean_assistant/core/network/network_module.dart' as _i49;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i583.GoRouter>(() => appModule.router);
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio(gh<_i345.AppConfig>()));
    gh.lazySingleton<_i150.ApiClient>(() => _i150.ApiClient(gh<_i361.Dio>()));
    return this;
  }
}

class _$AppModule extends _i637.AppModule {}

class _$NetworkModule extends _i49.NetworkModule {}
