import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/network/cursor_page.dart';

void main() {
  String asText(Object? json) => json! as String;

  test('reads the items and where the next page starts', () {
    final page = CursorPage<String>.fromJson({
      'items': ['a', 'b'],
      'nextCursor': 'next',
    }, asText);

    expect(page.items, ['a', 'b']);
    expect(page.nextCursor, 'next');
  });

  test('rejects a response that is not a page', () {
    expect(
      () => CursorPage<String>.fromJson({'users': <String>[]}, asText),
      throwsFormatException,
    );
  });
}
