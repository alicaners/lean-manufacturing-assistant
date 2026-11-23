/// A whole plant as `/api/factories/{id}/tree` returns it: departments,
/// their lines and the machines on them.
class PlantTree {
  const PlantTree({
    required this.id,
    required this.name,
    required this.code,
    required this.departments,
  });

  /// Throws [FormatException] if the tree has an unexpected shape.
  factory PlantTree.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'code': final String code,
      'departments': final Object? departments,
    }) {
      return PlantTree(
        id: id,
        name: name,
        code: code,
        departments: _listOf(departments, DepartmentNode.fromJson),
      );
    }
    throw const FormatException('Unexpected plant tree.');
  }

  final String id;
  final String name;
  final String code;
  final List<DepartmentNode> departments;
}

class DepartmentNode {
  const DepartmentNode({
    required this.id,
    required this.name,
    required this.lines,
  });

  factory DepartmentNode.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'lines': final Object? lines,
    }) {
      return DepartmentNode(
        id: id,
        name: name,
        lines: _listOf(lines, LineNode.fromJson),
      );
    }
    throw const FormatException('Unexpected department in plant tree.');
  }

  final String id;
  final String name;
  final List<LineNode> lines;
}

class LineNode {
  const LineNode({
    required this.id,
    required this.name,
    required this.machines,
  });

  factory LineNode.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'machines': final Object? machines,
    }) {
      return LineNode(
        id: id,
        name: name,
        machines: _listOf(machines, MachineNode.fromJson),
      );
    }
    throw const FormatException('Unexpected line in plant tree.');
  }

  final String id;
  final String name;
  final List<MachineNode> machines;
}

class MachineNode {
  const MachineNode({required this.id, required this.name, required this.code});

  factory MachineNode.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'code': final String code,
    }) {
      return MachineNode(id: id, name: name, code: code);
    }
    throw const FormatException('Unexpected machine in plant tree.');
  }

  final String id;
  final String name;

  /// Short code printed on the machine, e.g. "PR-01".
  final String code;
}

/// Which level of the tree something is on.
enum TreeNodeKind { department, line, machine }

List<T> _listOf<T>(Object? json, T Function(Object? json) item) {
  if (json is List<Object?>) return [for (final element in json) item(element)];
  throw const FormatException('Expected a list in plant tree.');
}
