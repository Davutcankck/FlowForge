import 'dart:convert';
import 'dart:math' as math;

import '../catalog/node_catalog.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_model.dart';
import 'node_name_deduplicator.dart';

/// [WorkflowModel] nesnesini n8n "Import from file" uyumlu JSON'a çevirir (SDD 5.3).
class N8nExporter {
  const N8nExporter();

  /// Modeli n8n JSON haritasına dönüştürür.
  ///
  /// Kurallar:
  /// 1. Node adları deterministik olarak benzersizleştirilir.
  /// 2. `connections` düğüm ID'si ile değil, benzersiz düğüm adı ile anahtarlanır.
  /// 3. `edge.outputIndex` değerine göre `main[outputIndex]` yazılır; boş kalan
  ///    alt indeksler (örn. IF'te yalnızca `false` bağlıysa `[[], [...]]`) korunur.
  /// 4. Pozisyon `[x, y]` tamsayı dizisi olarak yazılır.
  Map<String, dynamic> toMap(WorkflowModel model) {
    final uniqueNames = resolveUniqueNames(model);
    final nodeIds = model.nodes.map((n) => n.id).toSet();

    final nodesJson = <Map<String, dynamic>>[];
    for (final node in model.nodes) {
      final template = NodeCatalog.byKey(node.templateKey);
      if (template == null) {
        throw StateError('Katalogda bulunamayan şablon: ${node.templateKey}');
      }

      nodesJson.add({
        'id': node.id,
        'name': uniqueNames[node.id]!,
        'type': template.n8nType,
        'typeVersion': template.typeVersion,
        'position': [node.position.dx.round(), node.position.dy.round()],
        'parameters': Map<String, dynamic>.from(node.parameters),
      });
    }

    // Kenarları kaynak düğüme göre grupla.
    final edgesBySource = <String, List<WorkflowEdge>>{};
    for (final edge in model.edges) {
      if (!nodeIds.contains(edge.fromId) || !nodeIds.contains(edge.toId)) {
        continue;
      }
      edgesBySource.putIfAbsent(edge.fromId, () => []).add(edge);
    }

    final connectionsJson = <String, dynamic>{};
    for (final node in model.nodes) {
      final outgoing = edgesBySource[node.id];
      if (outgoing == null || outgoing.isEmpty) continue;

      final maxOutputIndex =
          outgoing.map((e) => e.outputIndex).reduce(math.max);
      final mainOutputs = List<List<Map<String, dynamic>>>.generate(
        maxOutputIndex + 1,
        (_) => <Map<String, dynamic>>[],
      );

      for (final edge in outgoing) {
        if (edge.outputIndex < 0) continue;
        mainOutputs[edge.outputIndex].add({
          'node': uniqueNames[edge.toId]!,
          'type': 'main',
          'index': 0,
        });
      }

      connectionsJson[uniqueNames[node.id]!] = {
        'main': mainOutputs,
      };
    }

    return {
      'name': model.name,
      'nodes': nodesJson,
      'connections': connectionsJson,
    };
  }

  /// Modeli deterministik, okunabilir n8n JSON metnine dönüştürür.
  String export(WorkflowModel model) {
    return const JsonEncoder.withIndent('  ').convert(toMap(model));
  }
}
