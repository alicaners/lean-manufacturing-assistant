import 'package:lean_assistant/core/error/failure.dart';

/// State of a form that sends one request.
/// Success has no state of its own: the page is left right after it.
sealed class SubmitState {
  const SubmitState();
}

/// Waiting for the user.
final class SubmitIdle extends SubmitState {
  const SubmitIdle();
}

/// The request is on its way; the button shows progress and ignores taps.
final class SubmitInProgress extends SubmitState {
  const SubmitInProgress();
}

/// The request failed; the page shows why.
final class SubmitFailed extends SubmitState {
  const SubmitFailed(this.failure);

  final Failure failure;
}
