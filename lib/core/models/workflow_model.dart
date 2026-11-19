import 'dart:ui';

import 'id_generator.dart';
import 'workflow_edge.dart';
import 'workflow_node.dart';

/// Tek doğruluk kaynağı: node ve edge'lerden oluşan immutable akış modeli.
///
/// Tüm değişiklik `copyWith` ile yeni bir nesne üretir; mevcut nesne asla
/// değiştirilmez. Bu sayede undo/redo ve golden testler deterministik kalır.
class WorkflowModel {
  WorkflowModel({
    required this.id,
    required this.name,
    required List<WorkflowNode> nodes,
    required List<WorkflowEdge> edges,
    required this.updatedAt,
    this.schemaVersion = 1,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges);

  /// Boş bir model oluşturur.
  factory WorkflowModel.empty({required IdGenerator gen}) {
    return WorkflowModel(
      id: gen.next(),
      name: 'FlowForge Workflow',
      nodes: const [],
      edges: const [],
      updatedAt: DateTime.now(),
    );
  }

  final String id;
  final String name;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final DateTime updatedAt;
  final int schemaVersion;

  /// Belirtilen id'ye sahip node'u döndürür, yoksa null.
  WorkflowNode? nodeById(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } on StateError {
      return null;
    }
  }

  /// Yeni bir node ekler ve güncellenmiş modeli döndürür (atomik, immutable).
  WorkflowModel addNode({
    required String templateKey,
    required String name,
    required Map<String, dynamic> parameters,
    required Offset position,
    required IdGenerator gen,
  }) {
    final newNode = WorkflowNode(
      id: gen.next(),
      templateKey: templateKey,
      name: name,
      parameters: Map<String, dynamic>.from(parameters),
      position: position,
    );
    return copyWith(
      nodes: [...nodes, newNode],
      updatedAt: DateTime.now(),
    );
  }

  /// Yeni bir edge ekler ve güncellenmiş modeli döndürür (atomik, immutable).
  WorkflowModel addEdge({
    required String fromId,
    required String toId,
    required int outputIndex,
  }) {
    final newEdge = WorkflowEdge(
      fromId: fromId,
      toId: toId,
      outputIndex: outputIndex,
    );
    return copyWith(
      edges: [...edges, newEdge],
      updatedAt: DateTime.now(),
    );
  }

  /// Belirtilen node'u ve ona bağlı tüm edge'leri kaldırır.
  WorkflowModel removeNode(String nodeId) {
    final remainingNodes = nodes.where((n) => n.id != nodeId).toList();
    final remainingEdges = edges.where(
      (e) => e.fromId != nodeId && e.toId != nodeId,
    ).toList();
    return copyWith(
      nodes: remainingNodes,
      edges: remainingEdges,
      updatedAt: DateTime.now(),
    );
  }

  WorkflowModel copyWith({
    String? id,
    String? name,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    DateTime? updatedAt,
    int? schemaVersion,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schemaVersion': schemaVersion,
      'updatedAt': updatedAt.toIso8601String(),
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    return WorkflowModel(
      id: json['id'] as String,
      name: json['name'] as String,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      nodes: (json['nodes'] as List<dynamic>)
          .map((e) => WorkflowNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      edges: (json['edges'] as List<dynamic>)
          .map((e) => WorkflowEdge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowModel &&
        other.id == id &&
        other.name == name &&
        _listEquals(other.nodes, nodes) &&
        _listEquals(other.edges, edges) &&
        other.updatedAt == updatedAt &&
        other.schemaVersion == schemaVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      nodes,
      edges,
      updatedAt,
      schemaVersion,
    );
  }

  @override
  String toString() {
    return 'WorkflowModel(id: $id, name: $name, nodes: ${nodes.length}, edges: ${edges.length})';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
