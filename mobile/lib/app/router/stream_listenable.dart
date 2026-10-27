import 'dart:async';

import 'package:flutter/foundation.dart';

/// Lets GoRouter re-run its redirect whenever [stream] emits,
/// e.g. on every change of the sign-in state.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
