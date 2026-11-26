import 'dart:math' as math;
import 'dart:ui';

import '../models/workflow_node.dart';
import 'auto_layout.dart';

/// Sahne koordinatlarında düğüm isabet testi yapan saf Dart yardımcı sınıfı.
///
/// Dokunma toleransı (slop) formülü:
/// `slop = max(0, (44 - rect.shortestSide * scale) / (2 * scale))`
class CanvasHitTester {
  const CanvasHitTester();

  static const double minTouchTargetPx = 44.0;

  /// Verilen [rect] ve [scale] için sahne birimi cinsinden dokunma toleransını hesaplar.
  static double computeSlop(Rect rect, double scale) {
    if (scale <= 0) return 0.0;
    return math.max(
      0.0,
      (minTouchTargetPx - rect.shortestSide * scale) / (2.0 * scale),
    );
  }

  /// [scenePoint] noktasına (z-sırasına göre en üstten başlayarak) isabet eden
  /// düğümü döndürür; boş alana tıklandıysa `null`.
  WorkflowNode? hitTest({
    required Offset scenePoint,
    required List<WorkflowNode> nodes,
    required LayoutResult layout,
    double scale = 1.0,
  }) {
    final rects = layout.sceneRects;
    for (var i = nodes.length - 1; i >= 0; i--) {
      final node = nodes[i];
      final rect = rects[node.id];
      if (rect == null) continue;

      final slop = computeSlop(rect, scale);
      final hitRect = slop > 0 ? rect.inflate(slop) : rect;
      if (hitRect.contains(scenePoint)) {
        return node;
      }
    }
    return null;
  }
}
