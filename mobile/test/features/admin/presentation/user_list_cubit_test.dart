import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/cursor_page.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_cubit.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_users.dart';

class _MockUserAdminRepository extends Mock implements UserAdminRepository {}

Result<CursorPage<ManagedUser>> _page(
  List<ManagedUser> users, {
  String? nextCursor,
}) => Ok(CursorPage(items: users, nextCursor: nextCursor));

TypeMatcher<UserListState> _state(
  UserListStatus status, {
  List<ManagedUser>? users,
}) {
  var matcher = isA<UserListState>().having(
    (state) => state.status,
    'status',
    status,
  );
  if (users != null) {
    matcher = matcher.having((state) => state.users, 'users', users);
  }
  return matcher;
}

void main() {
  late _MockUserAdminRepository repository;

  setUpAll(() => registerFallbackValue(const UserFilter()));

  setUp(() => repository = _MockUserAdminRepository());

  void givenList(Future<Result<CursorPage<ManagedUser>>> Function() answer) {
    when(() => repository.list(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) => answer());
  }

  blocTest<UserListCubit, UserListState>(
    'loads the first page',
    setUp: () =>
        givenList(() async => _page([operatorUser], nextCursor: 'next')),
    build: () => UserListCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      _state(UserListStatus.loading),
      _state(
        UserListStatus.ready,
        users: [operatorUser],
      ).having((state) => state.nextCursor, 'nextCursor', 'next'),
    ],
  );

  blocTest<UserListCubit, UserListState>(
    'adds the next page to the list',
    setUp: () => givenList(() async => _page([adminUser])),
    build: () => UserListCubit(repository),
    seed: () => const UserListState(
      status: UserListStatus.ready,
      users: [operatorUser],
      nextCursor: 'next',
    ),
    act: (cubit) => cubit.loadMore(),
    expect: () => [
      _state(
        UserListStatus.ready,
        users: [operatorUser],
      ).having((state) => state.isLoadingMore, 'isLoadingMore', isTrue),
      _state(
        UserListStatus.ready,
        users: [operatorUser, adminUser],
      ).having((state) => state.hasMore, 'hasMore', isFalse),
    ],
    verify: (_) =>
        verify(() => repository.list(any(), cursor: 'next')).called(1),
  );

  blocTest<UserListCubit, UserListState>(
    'searches once typing pauses',
    setUp: () => givenList(() async => _page([operatorUser])),
    build: () => UserListCubit(repository),
    act: (cubit) => cubit
      ..searchChanged('de')
      ..searchChanged('demo'),
    wait: UserListCubit.searchDelay * 2,
    expect: () => [
      _state(UserListStatus.loading),
      _state(UserListStatus.ready, users: [operatorUser]),
    ],
    verify: (_) {
      final filter =
          verify(
                () =>
                    repository.list(captureAny(), cursor: any(named: 'cursor')),
              ).captured.single
              as UserFilter;
      expect(filter.search, 'demo');
    },
  );

  blocTest<UserListCubit, UserListState>(
    'ignores the answer for a filter that was replaced',
    setUp: () =>
        when(
          () => repository.list(any(), cursor: any(named: 'cursor')),
        ).thenAnswer((invocation) async {
          final filter = invocation.positionalArguments.single as UserFilter;
          if (filter.role == UserRole.admin) return _page([adminUser]);

          // The answer for the old filter is slower than the new one.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _page([operatorUser]);
        }),
    build: () => UserListCubit(repository),
    act: (cubit) {
      unawaited(cubit.load());
      return cubit.roleChanged(UserRole.admin);
    },
    wait: const Duration(milliseconds: 100),
    expect: () => [
      _state(UserListStatus.loading),
      _state(UserListStatus.loading),
      _state(UserListStatus.ready, users: [adminUser]),
    ],
  );

  blocTest<UserListCubit, UserListState>(
    'shows why the first page could not be loaded',
    setUp: () => givenList(() async => const Err(NetworkFailure())),
    build: () => UserListCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      _state(UserListStatus.loading),
      _state(UserListStatus.failed)
          .having((state) => state.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
