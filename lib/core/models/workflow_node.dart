import 'dart:ui';

/// n8n workflow'da tek bir işlem adımı (tetikleyici, aksiyon, koşul, çıktı).
class WorkflowNode {
  const WorkflowNode({
    required this.id,
    required this.templateKey,
    required this.name,
    required this.parameters,
    required this.position,
  });

  final String id;
  final String templateKey; // katalog anahtarı (örn. 'webhook')
  final String name;        // workflow içinde benzersiz görünen ad
  final Map<String, dynamic> parameters;
  final Offset position;

  WorkflowNode copyWith({
    String? id,
    String? templateKey,
    String? name,
    Map<String, dynamic>? parameters,
    Offset? position,
  }) {
    return WorkflowNode(
      id: id ?? this.id,
      templateKey: templateKey ?? this.templateKey,
      name: name ?? this.name,
      parameters: parameters ?? this.parameters,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateKey': templateKey,
      'name': name,
      'parameters': parameters,
      'position': [position.dx, position.dy],
    };
  }

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as List<dynamic>;
    return WorkflowNode(
      id: json['id'] as String,
      templateKey: json['templateKey'] as String,
      name: json['name'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      position: Offset(pos[0] as double, pos[1] as double),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowNode &&
        other.id == id &&
        other.templateKey == templateKey &&
        other.name == name &&
        _mapEquals(other.parameters, parameters) &&
        other.position == position;
  }

  @override
  int get hashCode {
    final entries = parameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    var result = Object.hash(id, templateKey, name, position);
    for (final entry in entries) {
      result = result * 31 + Object.hash(entry.key, entry.value);
    }
    return result;
  }

  @override
  String toString() {
    return 'WorkflowNode(id: $id, templateKey: $templateKey, name: $name)';
  }
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (a[key] != b[key]) return false;
  }
  return true;
}