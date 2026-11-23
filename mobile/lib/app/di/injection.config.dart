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
import 'package:lean_assistant/core/network/network_module.dart' as _i50;
import 'package:lean_assistant/core/storage/storage_module.dart' as _i743;
import 'package:lean_assistant/features/admin/data/api_organization_repository.dart'
    as _i321;
import 'package:lean_assistant/features/admin/data/api_user_admin_repository.dart'
    as _i449;
import 'package:lean_assistant/features/admin/domain/organization_repository.dart'
    as _i188;
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart'
    as _i90;
import 'package:lean_assistant/features/admin/presentation/create_user_cubit.dart'
    as _i705;
import 'package:lean_assistant/features/admin/presentation/user_detail_cubit.dart'
    as _i503;
import 'package:lean_assistant/features/admin/presentation/user_list_cubit.dart'
    as _i153;
import 'package:lean_assistant/features/auth/data/api_auth_repository.dart'
    as _i223;
import 'package:lean_assistant/features/auth/data/auth_interceptor.dart'
    as _i636;
import 'package:lean_assistant/features/auth/data/session_refresher.dart'
    as _i387;
import 'package:lean_assistant/features/auth/data/session_store.dart' as _i274;
import 'package:lean_assistant/features/auth/domain/auth_repository.dart'
    as _i924;
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart'
    as _i348;
import 'package:lean_assistant/features/auth/presentation/change_password_cubit.dart'
    as _i501;
import 'package:lean_assistant/features/auth/presentation/login_cubit.dart'
    as _i49;
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
    final storageModule = _$StorageModule();
    final networkModule = _$NetworkModule();
    final appModule = _$AppModule();
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
    gh.lazySingleton<_i188.OrganizationRepository>(
      () => _i321.ApiOrganizationRepository(gh<_i150.ApiClient>()),
    );
    gh.lazySingleton<_i327.HealthRepository>(
      () => _i663.ApiHealthRepository(gh<_i150.ApiClient>()),
    );
    gh.lazySingleton<_i90.UserAdminRepository>(
      () => _i449.ApiUserAdminRepository(gh<_i150.ApiClient>()),
    );
    gh.lazySingleton<_i348.AuthBloc>(
      () => _i348.AuthBloc(gh<_i924.AuthRepository>()),
    );
    gh.factory<_i168.ServerStatusCubit>(
      () => _i168.ServerStatusCubit(gh<_i327.HealthRepository>()),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => appModule.router(gh<_i348.AuthBloc>()),
    );
    gh.factory<_i501.ChangePasswordCubit>(
      () => _i501.ChangePasswordCubit(
        gh<_i924.AuthRepository>(),
        gh<_i348.AuthBloc>(),
      ),
    );
    gh.factory<_i49.LoginCubit>(
      () => _i49.LoginCubit(gh<_i924.AuthRepository>(), gh<_i348.AuthBloc>()),
    );
    gh.factory<_i705.CreateUserCubit>(
      () => _i705.CreateUserCubit(
        gh<_i90.UserAdminRepository>(),
        gh<_i188.OrganizationRepository>(),
      ),
    );
    gh.factory<_i503.UserDetailCubit>(
      () => _i503.UserDetailCubit(gh<_i90.UserAdminRepository>()),
    );
    gh.factory<_i153.UserListCubit>(
      () => _i153.UserListCubit(gh<_i90.UserAdminRepository>()),
    );
    return this;
  }
}

class _$StorageModule extends _i743.StorageModule {}

class _$NetworkModule extends _i50.NetworkModule {}

class _$AppModule extends _i637.AppModule {}
