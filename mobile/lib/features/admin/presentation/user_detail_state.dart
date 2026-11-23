import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/admin/domain/managed_user.dart';

enum UserDetailStatus { loading, ready, failed }

/// What an admin can do on the detail page.
enum UserAction { activate, deactivate, resetPassword }

class UserDetailState {
  const UserDetailState({
    this.status = UserDetailStatus.loading,
    this.user,
    this.loadFailure,
    this.action = const SubmitIdle(),
    this.lastAction,
  });

  final UserDetailStatus status;
  final ManagedUser? user;

  /// Why the user could not be loaded.
  final Failure? loadFailure;

  /// The state of the action the admin started last.
  final SubmitState action;

  /// Which action [action] belongs to, so the page can say what happened.
  final UserAction? lastAction;
}
