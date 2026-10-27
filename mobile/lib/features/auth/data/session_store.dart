import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

/// Keeps the session on the device between app starts.
abstract interface class SessionStore {
  /// The kept session, or null when signed out.
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

/// [SessionStore] in the platform's encrypted storage:
/// Android Keystore on Android, Keychain on iOS.
@LazySingleton(as: SessionStore)
class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage);

  static const String storageKey = 'auth.session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final raw = await _storage.read(key: storageKey);
      return raw == null ? null : AuthSession.fromJson(jsonDecode(raw));
    } on FormatException {
      // Written by an older app version or damaged: start signed out.
      await clear();
      return null;
    } on PlatformException {
      // The encryption key is gone, e.g. after restoring a backup on a new phone.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) {
    return _storage.write(key: storageKey, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}
