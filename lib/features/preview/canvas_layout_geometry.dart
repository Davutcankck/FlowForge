import 'dart:math' as math;
import 'dart:ui';

import '../../core/catalog/node_catalog.dart';
import '../../core/catalog/node_category.dart';
import '../../core/models/workflow_model.dart';
import '../../core/models/workflow_node.dart';

/// [WorkflowCanvasPainter] ve [PreviewScreen] hit-testing arasında paylaşılan
/// saf koordinat ve tuval geometrisi hesaplayıcısı.
class CanvasLayoutGeometry {
  CanvasLayoutGeometry._({
    required this.canvasSize,
    required this.originOffset,
    required this.nodeRects,
    required this.nodes,
  });

  static const double standardWidth = 160.0;
  static const double standardHeight = 64.0;
  static const double logicWidth = 128.0;
  static const double logicHeight = 84.0;
  static const double padding = 80.0;
  static const double minCanvasWidth = 420.0;
  static const double minCanvasHeight = 320.0;

  final Size canvasSize;
  final Offset originOffset;
  final Map<String, Rect> nodeRects;
  final List<WorkflowNode> nodes;

  /// Verilen [model] için tuval boyutunu ve her düğümün tuval içindeki [Rect]
  /// konumunu deterministik olarak hesaplar. Boş modelde güvenle minimum boyut döner.
  factory CanvasLayoutGeometry.fromModel(WorkflowModel model) {
    if (model.nodes.isEmpty) {
      return CanvasLayoutGeometry._(
        canvasSize: const Size(minCanvasWidth, minCanvasHeight),
        originOffset: Offset.zero,
        nodeRects: const {},
        nodes: const [],
      );
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    final rawSizes = <String, Size>{};
    for (final node in model.nodes) {
      final size = sizeForNode(node);
      rawSizes[node.id] = size;

      final left = node.position.dx;
      final top = node.position.dy;
      final right = left + size.width;
      final bottom = top + size.height;

      if (left < minX) minX = left;
      if (top < minY) minY = top;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final originOffset = Offset(padding - minX, padding - minY);
    final width = math.max(minCanvasWidth, (maxX - minX) + padding * 2);
    final height = math.max(minCanvasHeight, (maxY - minY) + padding * 2);

    final rects = <String, Rect>{};
    for (final node in model.nodes) {
      final size = rawSizes[node.id]!;
      rects[node.id] = Rect.fromLTWH(
        node.position.dx + originOffset.dx,
        node.position.dy + originOffset.dy,
        size.width,
        size.height,
      );
    }

    return CanvasLayoutGeometry._(
      canvasSize: Size(width, height),
      originOffset: originOffset,
      nodeRects: Map.unmodifiable(rects),
      nodes: model.nodes,
    );
  }

  /// Düğüm kategorisine göre çizim boyutunu döndürür.
  static Size sizeForNode(WorkflowNode node) {
    final category = NodeCatalog.byKey(node.templateKey)?.category;
    if (category == NodeCategory.logic) {
      return const Size(logicWidth, logicHeight);
    }
    return const Size(standardWidth, standardHeight);
  }

  /// Verilen [nodeId] için tuval içi [Rect] alanını döndürür.
  Rect? rectFor(String nodeId) => nodeRects[nodeId];

  /// Tuval koordinatlarındaki [localPosition] noktasına isabet eden düğümü döndürür.
  /// Logic düğümlerinde eşkenar dörtgen (rhombus) içi kontrolü uygulanır.
  WorkflowNode? hitTest(Offset localPosition) {
    for (var i = nodes.length - 1; i >= 0; i--) {
      final node = nodes[i];
      final rect = nodeRects[node.id];
      if (rect == null || !rect.contains(localPosition)) continue;

      final category = NodeCatalog.byKey(node.templateKey)?.category;
      if (category == NodeCategory.logic) {
        final cx = rect.center.dx;
        final cy = rect.center.dy;
        final rx = rect.width / 2;
        final ry = rect.height / 2;
        final normalized =
            ((localPosition.dx - cx).abs() / rx) +
            ((localPosition.dy - cy).abs() / ry);
        if (normalized <= 1.0) {
          return node;
        }
      } else {
        return node;
      }
    }
    return null;
  }
}
