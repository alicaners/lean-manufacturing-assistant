import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/admin/domain/user_admin_repository.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';
import 'package:lean_assistant/features/admin/presentation/user_list_state.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// Loads the user list page by page and reloads it when the filter changes.
@injectable
class UserListCubit extends Cubit<UserListState> {
  UserListCubit(this._repository) : super(const UserListState());

  /// How long typing must pause before a search is sent.
  static const Duration searchDelay = Duration(milliseconds: 400);

  final UserAdminRepository _repository;
  Timer? _searchTimer;

  /// Grows with every first-page request. An answer that arrives after a newer
  /// request has started belongs to an old filter and is thrown away.
  int _request = 0;

  /// Loads the first page for [filter] (or the current one).
  /// Also used by pull-to-refresh and the retry button.
  Future<void> load({UserFilter? filter}) async {
    final request = ++_request;
    final current = filter ?? state.filter;

    // The old list stays visible until the new one arrives.
    emit(UserListState(filter: current, users: state.users));

    final result = await _repository.list(current);

    if (isClosed || request != _request) return;

    emit(switch (result) {
      Ok(:final value) => UserListState(
        filter: current,
        status: UserListStatus.ready,
        users: value.items,
        nextCursor: value.nextCursor,
      ),
      Err(:final failure) => UserListState(
        filter: current,
        status: UserListStatus.failed,
        failure: failure,
      ),
    });
  }

  /// Called on every keystroke; searches once typing pauses.
  void searchChanged(String search) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      if (search.trim() == state.filter.search.trim()) return;
      unawaited(load(filter: state.filter.withSearch(search)));
    });
  }

  Future<void> roleChanged(UserRole? role) =>
      load(filter: state.filter.withRole(role));

  Future<void> activeChanged(bool? isActive) =>
      load(filter: state.filter.withActive(isActive));

  /// Loads the page after the last one, unless one is already on its way,
  /// there is none, or the last attempt failed (see [retryLoadMore]).
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (isClosed ||
        state.status != UserListStatus.ready ||
        cursor == null ||
        state.isLoadingMore ||
        state.loadMoreFailure != null) {
      return;
    }

    final request = _request;
    final filter = state.filter;
    final users = state.users;

    emit(
      UserListState(
        filter: filter,
        status: UserListStatus.ready,
        users: users,
        nextCursor: cursor,
        isLoadingMore: true,
      ),
    );

    final result = await _repository.list(filter, cursor: cursor);

    // The filter changed while this page was loading: it is not wanted any more.
    if (isClosed || request != _request) return;

    emit(switch (result) {
      Ok(:final value) => UserListState(
        filter: filter,
        status: UserListStatus.ready,
        users: [...users, ...value.items],
        nextCursor: value.nextCursor,
      ),
      Err(:final failure) => UserListState(
        filter: filter,
        status: UserListStatus.ready,
        users: users,
        nextCursor: cursor,
        loadMoreFailure: failure,
      ),
    });
  }

  Future<void> retryLoadMore() {
    emit(
      UserListState(
        filter: state.filter,
        status: UserListStatus.ready,
        users: state.users,
        nextCursor: state.nextCursor,
      ),
    );
    return loadMore();
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
