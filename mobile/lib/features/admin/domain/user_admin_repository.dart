import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/cursor_page.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/admin/domain/new_user.dart';
import 'package:lean_assistant/features/admin/domain/user_filter.dart';

/// User management for admins.
abstract interface class UserAdminRepository {
  /// One page of users that match [filter]. Pass the previous page's
  /// `nextCursor` as [cursor] to get the page after it.
  Future<Result<CursorPage<ManagedUser>>> list(
    UserFilter filter, {
    String? cursor,
  });

  /// Creates the user with a temporary password they must change at
  /// first sign-in.
  Future<Result<ManagedUser>> create(NewUser user);
}
