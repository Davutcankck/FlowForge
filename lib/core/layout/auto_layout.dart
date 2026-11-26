import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import '../catalog/node_catalog.dart';
import '../catalog/node_category.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_model.dart';
import '../models/workflow_node.dart';

/// [AutoLayout.compute] çıktısı — tek geometri doğruluk kaynağı.
///
/// `model` alanı içermez (çift doğruluk kaynağını önlemek için).
/// - [nodeRects]: Ham yerleşim koordinatları (negatif `y` içerebilir); exporter'lar bunu kullanır.
/// - [originOffset]: Negatif koordinatları pozitif tuval uzayına taşıyan ofset.
/// - [sceneRects]: `nodeRects + originOffset`; painter ve [CanvasHitTester] bunu kullanır.
/// - [canvasSize]: Tüm düğümleri + padding'i kapsayan dinamik tuval boyutu.
class LayoutResult {
  LayoutResult({
    required Map<String, Rect> nodeRects,
    required this.originOffset,
    required this.canvasSize,
  }) : nodeRects = Map.unmodifiable(nodeRects);

  final Map<String, Rect> nodeRects;
  final Offset originOffset;
  final Size canvasSize;

  /// Tuval/sahne koordinatlarındaki düğüm dikdörtgenleri (`nodeRects + originOffset`).
  Map<String, Rect> get sceneRects => Map.unmodifiable({
        for (final entry in nodeRects.entries)
          entry.key: entry.value.shift(originOffset),
      });
}

/// Akış düğümlerini otomatik ve deterministik olarak konumlandırır (SDD 5.2).
///
/// - Tüm düğümler (IF dahil) tek tip `140 x 60` boyutundadır.
/// - `x = derinlik * 250`, `y = sıra * 120`, IF dallarında `true: -60`, `false: +60`.
/// - Döngülü (cycle) akışlarda `visited` koruması ile sonsuz döngüye girmez.
/// - Bağlantısız (orphan) düğümler ana akışın altına deterministik yerleştirilir.
class AutoLayout {
  const AutoLayout();

  static const double nodeWidth = 140.0;
  static const double nodeHeight = 60.0;
  static const double xSpacing = 250.0;
  static const double ySpacing = 120.0;
  static const double ifBranchOffset = 60.0;
  static const double canvasPadding = 80.0;
  static const double minCanvasWidth = 420.0;
  static const double minCanvasHeight = 320.0;

  /// Model için deterministik [LayoutResult] hesaplar; [model]'i değiştirmez.
  LayoutResult compute(WorkflowModel model) {
    if (model.nodes.isEmpty) {
      return LayoutResult(
        nodeRects: const {},
        originOffset: Offset.zero,
        canvasSize: const Size(minCanvasWidth, minCanvasHeight),
      );
    }

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

    final nodeRects = <String, Rect>{};
    var minX = double.infinity;
    var minY = double.infinity;
    var maxRight = double.negativeInfinity;
    var maxBottom = double.negativeInfinity;

    for (final node in model.nodes) {
      final pos = positions[node.id] ?? Offset.zero;
      final rect = Rect.fromLTWH(pos.dx, pos.dy, nodeWidth, nodeHeight);
      nodeRects[node.id] = rect;

      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxRight) maxRight = rect.right;
      if (rect.bottom > maxBottom) maxBottom = rect.bottom;
    }

    final originOffset = Offset(canvasPadding - minX, canvasPadding - minY);
    final canvasWidth = math.max(
      minCanvasWidth,
      (maxRight - minX) + canvasPadding * 2,
    );
    final canvasHeight = math.max(
      minCanvasHeight,
      (maxBottom - minY) + canvasPadding * 2,
    );

    return LayoutResult(
      nodeRects: nodeRects,
      originOffset: originOffset,
      canvasSize: Size(canvasWidth, canvasHeight),
    );
  }
}
