/// What a machine's QR label holds, and how the app reads it back.
///
/// The label carries a prefix before the machine's QR code, so a scanner
/// can tell our labels from any other QR code (a web address, a product).
abstract final class MachineQr {
  static const String _prefix = 'leanassistant:machine:';

  /// Length of the server's QR codes (backend: Machine.QrCodeLength).
  static const int _qrCodeLength = 22;

  /// The text to put in the QR image of a machine.
  static String payloadOf(String qrCode) => '$_prefix$qrCode';

  /// The machine's QR code from a scanned label, or null if the scanned
  /// text is not one of our labels.
  static String? qrCodeFrom(String payload) {
    if (!payload.startsWith(_prefix)) return null;

    final qrCode = payload.substring(_prefix.length);
    return qrCode.length == _qrCodeLength ? qrCode : null;
  }
}
