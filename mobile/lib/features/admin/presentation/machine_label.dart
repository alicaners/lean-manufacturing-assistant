import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Draws a printable label: the QR code with the machine's name and code
/// under it, on white. Returns PNG bytes.
Future<Uint8List> renderMachineLabel({
  required String payload,
  required String name,
  required String code,
}) async {
  const width = 600.0;
  const qrSize = 520.0;
  const padding = 40.0;
  const textWidth = width - 2 * padding;

  final title = TextPainter(
    text: TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: textWidth);

  final subtitle = TextPainter(
    text: TextSpan(
      text: code,
      style: const TextStyle(color: Colors.black54, fontSize: 32),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: textWidth);

  final height =
      padding + qrSize + 24 + title.height + 8 + subtitle.height + padding;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      const Rect.fromLTWH(0, 0, width, 10000),
      Paint()..color = Colors.white,
    );

  // The QR code, centered at the top.
  canvas
    ..save()
    ..translate((width - qrSize) / 2, padding);
  QrPainter(
    data: payload,
    version: QrVersions.auto,
    gapless: true,
  ).paint(canvas, const Size.square(qrSize));
  canvas.restore();

  // Name and code under it, centered.
  const titleTop = padding + qrSize + 24;
  title.paint(canvas, Offset((width - title.width) / 2, titleTop));
  subtitle.paint(
    canvas,
    Offset((width - subtitle.width) / 2, titleTop + title.height + 8),
  );

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) throw StateError('The label could not be encoded.');

  return bytes.buffer.asUint8List();
}
