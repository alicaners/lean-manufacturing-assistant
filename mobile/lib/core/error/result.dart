import 'package:lean_assistant/core/error/failure.dart';

/// Outcome of an operation that can fail: either [Ok] with a value
/// or [Err] with a [Failure]. Errors are values, not exceptions.
sealed class Result<T> {
  const Result();
}

/// Successful outcome.
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

/// Failed outcome.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
