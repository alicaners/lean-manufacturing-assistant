import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter runs this before every test file under `test/`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(
      // Any file name works; only its folder is used to find the goldens.
      comparator.basedir.resolve('golden_test.dart'),
    );
  }

  await testMain();
}

/// Accepts tiny pixel differences, so a golden made on Windows also passes
/// on the Linux CI machine, where edges are smoothed slightly differently.
/// A real layout change (a moved button, a new color) differs far more.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile);

  /// Share of pixels that may differ: 1 %.
  static const double _tolerance = 0.01;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= _tolerance) return true;

    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}
