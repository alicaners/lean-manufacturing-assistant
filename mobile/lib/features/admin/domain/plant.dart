/// A plant (the backend calls it Factory). Every user except a system-wide
/// admin belongs to one.
class Plant {
  const Plant({required this.id, required this.name, required this.code});

  /// Throws [FormatException] if the JSON does not have the expected shape.
  factory Plant.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'code': final String code,
    }) {
      return Plant(id: id, name: name, code: code);
    }

    throw const FormatException('Unexpected plant response.');
  }

  final String id;
  final String name;

  /// Short unique code, e.g. "DEMO-IZM".
  final String code;
}

/// A production line, with the name of the department it belongs to.
class PlantLine {
  const PlantLine({
    required this.id,
    required this.name,
    required this.departmentName,
  });

  /// Every line of a plant tree (`/api/factories/{id}/tree`), department by
  /// department. Throws [FormatException] if the tree has an unexpected shape.
  static List<PlantLine> listFromTree(Object? json) {
    if (json case {'departments': final List<Object?> departments}) {
      final lines = <PlantLine>[];

      for (final department in departments) {
        if (department case {
          'name': final String departmentName,
          'lines': final List<Object?> departmentLines,
        }) {
          for (final line in departmentLines) {
            if (line case {'id': final String id, 'name': final String name}) {
              lines.add(
                PlantLine(id: id, name: name, departmentName: departmentName),
              );
            } else {
              throw const FormatException('Unexpected line in plant tree.');
            }
          }
        } else {
          throw const FormatException('Unexpected department in plant tree.');
        }
      }

      return lines;
    }

    throw const FormatException('Unexpected plant tree.');
  }

  final String id;
  final String name;
  final String departmentName;
}
