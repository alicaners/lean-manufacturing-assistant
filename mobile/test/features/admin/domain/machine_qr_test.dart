import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/admin/domain/machine_qr.dart';

const _qrCode = 'abcdefghijklmnopqrstuv';

void main() {
  test('reads back the code it put on the label', () {
    final payload = MachineQr.payloadOf(_qrCode);

    expect(payload, 'leanassistant:machine:$_qrCode');
    expect(MachineQr.qrCodeFrom(payload), _qrCode);
  });

  test('ignores QR codes that are not machine labels', () {
    expect(MachineQr.qrCodeFrom('https://example.com'), isNull);
    expect(MachineQr.qrCodeFrom(_qrCode), isNull);
    expect(MachineQr.qrCodeFrom('leanassistant:machine:short'), isNull);
  });
}
