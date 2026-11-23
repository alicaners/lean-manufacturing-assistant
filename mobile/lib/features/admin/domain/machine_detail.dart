/// One machine with its QR code, as `/api/machines/{id}` returns it.
class MachineDetail {
  const MachineDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.qrCode,
  });

  /// Throws [FormatException] if the JSON does not have the expected shape.
  factory MachineDetail.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'code': final String code,
      'qrCode': final String qrCode,
    }) {
      return MachineDetail(id: id, name: name, code: code, qrCode: qrCode);
    }
    throw const FormatException('Unexpected machine response.');
  }

  final String id;
  final String name;

  /// Short code printed on the machine, e.g. "PR-01".
  final String code;

  /// Random code the label carries; the server finds the machine by it.
  final String qrCode;
}
