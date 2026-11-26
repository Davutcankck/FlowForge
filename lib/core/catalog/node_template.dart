import 'package:flutter/foundation.dart';
import 'node_category.dart';

/// n8n node şablonunu temsil eden değişmez (immutable) sınıf.
@immutable
class NodeTemplate {
  final String key;
  final String displayName;
  final NodeCategory category;
  final String n8nType;
  final num typeVersion; // TODO(verify-n8n)
  final Map<String, dynamic> defaultParameters;
  final List<String> requiredParameters;
  final int outputs;
  final String drawioStyle;

  const NodeTemplate({
    required this.key,
    required this.displayName,
    required this.category,
    required this.n8nType,
    required this.typeVersion,
    required this.defaultParameters,
    this.requiredParameters = const [],
    required this.outputs,
    required this.drawioStyle,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NodeTemplate && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'NodeTemplate(key: $key, category: $category)';
}
