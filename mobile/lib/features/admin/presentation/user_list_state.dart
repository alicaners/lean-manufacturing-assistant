import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';

enum UserListStatus {
  /// The first page for the current filter is on its way.
  loading,

  /// The list is shown; more pages may follow.
  ready,

  /// The first page could not be loaded.
  failed,
}

/// Everything the user list shows.
class UserListState {
  const UserListState({
    this.filter = const UserFilter(),
    this.status = UserListStatus.loading,
    this.users = const [],
    this.nextCursor,
    this.failure,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final UserFilter filter;
  final UserListStatus status;

  /// Every page loaded so far, in order. While a new filter loads,
  /// the previous list stays visible.
  final List<ManagedUser> users;

  /// Where the next page starts; null when there is none.
  final String? nextCursor;

  /// Why the first page could not be loaded.
  final Failure? failure;

  final bool isLoadingMore;

  /// Why the next page could not be loaded; the list stays as it is.
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;
}
