import 'dart:collection';
import 'dart:ui';

import '../catalog/node_catalog.dart';
import '../catalog/node_category.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_model.dart';
import '../models/workflow_node.dart';

/// Akış düğümlerini otomatik ve deterministik olarak konumlandırır.
///
/// Formül (SDD 5.2):
/// - `x = derinlik * 250`
/// - `y = aynı derinlikteki sıra * 120`
/// - IF dallarında `true` kolu `-60`, `false` kolu `+60` kaydırılır.
/// - Döngülü (cycle) akışlarda `visited` koruması ile sonsuz döngüye girmez.
/// - Bağlantısız (orphan) düğümler ana akışın altına deterministik yerleştirilir.
class AutoLayout {
  const AutoLayout();

  static const double xSpacing = 250.0;
  static const double ySpacing = 120.0;
  static const double ifBranchOffset = 60.0;

  /// Mevcut modeli değiştirmeden düğüm pozisyonları güncellenmiş yeni bir
  /// [WorkflowModel] döndürür.
  WorkflowModel apply(WorkflowModel model) {
    if (model.nodes.isEmpty) return model;

    final nodeById = <String, WorkflowNode>{
      for (final node in model.nodes) node.id: node,
    };

    final outgoing = <String, List<WorkflowEdge>>{};
    final inDegree = <String, int>{
      for (final node in model.nodes) node.id: 0,
    };

    for (final edge in model.edges) {
      if (!nodeById.containsKey(edge.fromId) ||
          !nodeById.containsKey(edge.toId)) {
        continue;
      }
      outgoing.putIfAbsent(edge.fromId, () => []).add(edge);
      inDegree[edge.toId] = (inDegree[edge.toId] ?? 0) + 1;
    }

    // Kök önceliği: önce trigger kategorisindeki node'lar, sonra gelen kenarı
    // olmayan (inDegree == 0) düğümler.
    final roots = <String>[];
    final rootSet = <String>{};

    for (final node in model.nodes) {
      final template = NodeCatalog.byKey(node.templateKey);
      if (template?.category == NodeCategory.trigger && rootSet.add(node.id)) {
        roots.add(node.id);
      }
    }

    for (final node in model.nodes) {
      if ((inDegree[node.id] ?? 0) == 0 && rootSet.add(node.id)) {
        roots.add(node.id);
      }
    }

    // Tamamen döngüsel ve triggersız akışlar için ilk düğümü kök kabul et.
    if (roots.isEmpty) {
      roots.add(model.nodes.first.id);
    }

    final visited = <String>{};
    final positions = <String, Offset>{};
    final occupiedYByDepth = <int, Set<double>>{};
    final slotCountByDepthAndOffset = <(int, double), int>{};

    void bfsFrom(String startId, double baseY) {
      final queue = Queue<(String id, int depth, double branchOffset)>();
      visited.add(startId);
      queue.add((startId, 0, baseY));

      while (queue.isNotEmpty) {
        final (nodeId, depth, branchOffset) = queue.removeFirst();
        final node = nodeById[nodeId]!;

        final slotKey = (depth, branchOffset);
        final rank = slotCountByDepthAndOffset[slotKey] ?? 0;
        slotCountByDepthAndOffset[slotKey] = rank + 1;

        var y = branchOffset + rank * ySpacing;
        final occupied = occupiedYByDepth.putIfAbsent(depth, () => <double>{});
        while (occupied.contains(y)) {
          y += ySpacing;
        }
        occupied.add(y);

        positions[nodeId] = Offset(depth * xSpacing, y);

        final edges = outgoing[nodeId] ?? const <WorkflowEdge>[];
        for (final edge in edges) {
          if (visited.contains(edge.toId)) continue;
          visited.add(edge.toId);

          double nextBranchOffset = branchOffset;
          if (node.templateKey == 'if') {
            if (edge.outputIndex == 0) {
              nextBranchOffset = branchOffset - ifBranchOffset;
            } else if (edge.outputIndex == 1) {
              nextBranchOffset = branchOffset + ifBranchOffset;
            }
          }

          queue.add((edge.toId, depth + 1, nextBranchOffset));
        }
      }
    }

    for (final rootId in roots) {
      if (!visited.contains(rootId)) {
        bfsFrom(rootId, 0.0);
      }
    }

    // Köklerden ulaşılamayan bağlantısız (orphan) veya ayrık döngülü düğümler.
    var maxY = 0.0;
    for (final pos in positions.values) {
      if (pos.dy > maxY) {
        maxY = pos.dy;
      }
    }

    var orphanBaseY = positions.isEmpty ? 0.0 : maxY + ySpacing;
    for (final node in model.nodes) {
      if (!visited.contains(node.id)) {
        bfsFrom(node.id, orphanBaseY);
        for (final pos in positions.values) {
          if (pos.dy > maxY) {
            maxY = pos.dy;
          }
        }
        orphanBaseY = maxY + ySpacing;
      }
    }

    final updatedNodes = model.nodes
        .map((node) => node.copyWith(position: positions[node.id] ?? Offset.zero))
        .toList();

    return model.copyWith(nodes: updatedNodes);
  }
}
