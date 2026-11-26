import 'dart:convert';
import 'dart:math' as math;

import '../catalog/node_catalog.dart';
import '../layout/auto_layout.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_model.dart';
import 'node_name_deduplicator.dart';

/// [WorkflowModel] nesnesini n8n "Import from file" uyumlu JSON'a çevirir (SDD 5.3).
class N8nExporter {
  const N8nExporter();

  /// Modeli SDD 5.3 sırasına uygun n8n JSON haritasına dönüştürür.
  ///
  /// Kurallar:
  /// 1. Üst düzey anahtar sırası: `name`, `nodes`, `connections`, `active`,
  ///    `settings`, `pinData`, `meta`.
  /// 2. Node adları deterministik olarak benzersizleştirilir; `connections`
  ///    düğüm ID'si ile değil, benzersiz düğüm adı ile anahtarlanır.
  /// 3. Pozisyonlar `node.position` yerine [LayoutResult.nodeRects] üzerinden okunur.
  /// 4. Modelde `respondToWebhook` varsa `webhook` düğümlerine (kullanıcı elle
  ///    belirtmediyse) `responseMode: 'responseNode'` eklenir.
  /// 5. `edge.outputIndex` indeks sırası boş çıkışlarda bile (`[[], [...]]`) korunur.
  Map<String, dynamic> toMap(
    WorkflowModel model, {
    LayoutResult? layout,
  }) {
    final resolvedLayout = layout ?? const AutoLayout().compute(model);
    final uniqueNames = resolveUniqueNames(model);
    final nodeIds = model.nodes.map((n) => n.id).toSet();
    final hasRespondToWebhook =
        model.nodes.any((n) => n.templateKey == 'respondToWebhook');

    final nodesJson = <Map<String, dynamic>>[];
    for (final node in model.nodes) {
      final template = NodeCatalog.byKey(node.templateKey);
      if (template == null) {
        throw StateError('Katalogda bulunamayan şablon: ${node.templateKey}');
      }

      final rect = resolvedLayout.nodeRects[node.id];
      final x = rect?.left.round() ?? 0;
      final y = rect?.top.round() ?? 0;

      final params = Map<String, dynamic>.from(node.parameters);
      if (hasRespondToWebhook &&
          node.templateKey == 'webhook' &&
          !params.containsKey('responseMode')) {
        params['responseMode'] = 'responseNode';
      }

      nodesJson.add({
        'id': node.id,
        'name': uniqueNames[node.id]!,
        'type': template.n8nType,
        'typeVersion': template.typeVersion,
        'position': [x, y],
        'parameters': params,
      });
    }

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

    return <String, dynamic>{
      'name': model.name,
      'nodes': nodesJson,
      'connections': connectionsJson,
      'active': false,
      'settings': <String, dynamic>{
        'executionOrder': 'v1',
      },
      'pinData': <String, dynamic>{},
      'meta': <String, dynamic>{
        'instanceId': '',
      },
    };
  }

  /// Modeli deterministik, LF satır sonlu n8n JSON metnine dönüştürür.
  String export(
    WorkflowModel model, {
    LayoutResult? layout,
  }) {
    return const JsonEncoder.withIndent('  ')
        .convert(toMap(model, layout: layout));
  }
}
