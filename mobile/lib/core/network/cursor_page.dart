/// One page of a list, as the API returns it. Send [nextCursor] back to get
/// the next page; null means this was the last page.
class CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  /// [item] turns each element of `items` into a model.
  /// Throws [FormatException] if the page does not have the expected shape.
  factory CursorPage.fromJson(Object? json, T Function(Object? json) item) {
    if (json case {
      'items': final List<Object?> items,
      'nextCursor': final String? nextCursor,
    }) {
      return CursorPage(
        items: [for (final element in items) item(element)],
        nextCursor: nextCursor,
      );
    }

    throw const FormatException('Unexpected page response.');
  }

  final List<T> items;
  final String? nextCursor;
}
