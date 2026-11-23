import 'package:flutter/material.dart';

/// A round avatar with a user's initials: "Ayşe Nur Demir" → "AN".
class UserAvatar extends StatelessWidget {
  const UserAvatar(this.fullName, {super.key, this.radius});

  final String fullName;

  /// Null uses the default size of a list row.
  final double? radius;

  String get _initials => fullName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final size = radius;

    return CircleAvatar(
      radius: size,
      child: Text(
        _initials,
        style: size == null ? null : TextStyle(fontSize: size * 0.7),
      ),
    );
  }
}
