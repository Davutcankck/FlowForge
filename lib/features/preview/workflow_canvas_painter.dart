import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/catalog/node_catalog.dart';
import '../../core/catalog/node_category.dart';
import '../../core/layout/auto_layout.dart';
import '../../core/models/workflow_model.dart';
import '../../core/models/workflow_node.dart';

/// Akış düğümlerini ve yönlü bağlantıları [LayoutResult.sceneRects] üzerinden çizen
/// [CustomPainter] (SDD 6.1).
class WorkflowCanvasPainter extends CustomPainter {
  WorkflowCanvasPainter({
    required this.model,
    required this.layout,
    required this.warningNodeIds,
    required this.isDark,
  });

  final WorkflowModel model;
  final LayoutResult layout;
  final Set<String> warningNodeIds;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (model.nodes.isEmpty) return;

    final sceneRects = layout.sceneRects;
    final nodeById = <String, WorkflowNode>{
      for (final node in model.nodes) node.id: node,
    };

    // 1. Önce bağlantıları (edges) çiz
    for (final edge in model.edges) {
      final fromRect = sceneRects[edge.fromId];
      final toRect = sceneRects[edge.toId];
      final fromNode = nodeById[edge.fromId];
      if (fromRect == null || toRect == null || fromNode == null) continue;

      final start = Offset(fromRect.center.dx, fromRect.bottom);
      final end = Offset(toRect.center.dx, toRect.top);

      String? label;
      if (fromNode.templateKey == 'if') {
        if (edge.outputIndex == 0) {
          label = 'true';
        } else if (edge.outputIndex == 1) {
          label = 'false';
        }
      }

      _drawEdge(canvas, start, end, label: label);
    }

    // 2. Düğümleri (nodes) çiz
    for (final node in model.nodes) {
      final rect = sceneRects[node.id];
      if (rect == null) continue;
      _drawNode(canvas, node, rect);
    }
  }

  void _drawEdge(
    Canvas canvas,
    Offset start,
    Offset end, {
    String? label,
  }) {
    final edgeColor =
        isDark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A);
    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final midY = (start.dy + end.dy) / 2;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);

    canvas.drawPath(path, paint);

    const arrowLength = 10.0;
    const arrowAngle = math.pi / 6;
    final angle = math.atan2(end.dy - midY, 0.0);
    final p1 = Offset(
      end.dx - arrowLength * math.cos(angle - arrowAngle),
      end.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final p2 = Offset(
      end.dx - arrowLength * math.cos(angle + arrowAngle),
      end.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.fill,
    );

    if (label != null) {
      final labelCenter = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );
      final isTrue = label == 'true';
      final pillFill = isDark
          ? (isTrue ? const Color(0xFF1B3B2B) : const Color(0xFF4A1D1D))
          : (isTrue ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE));
      final pillText = isDark
          ? (isTrue ? const Color(0xFF81C784) : const Color(0xFFEF9A9A))
          : (isTrue ? const Color(0xFF2E7D32) : const Color(0xFFC62828));

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: pillText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: labelCenter,
          width: textPainter.width + 12,
          height: textPainter.height + 4,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(pillRect, Paint()..color = pillFill);
      textPainter.paint(
        canvas,
        Offset(
          labelCenter.dx - textPainter.width / 2,
          labelCenter.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawNode(Canvas canvas, WorkflowNode node, Rect rect) {
    final category =
        NodeCatalog.byKey(node.templateKey)?.category ?? NodeCategory.output;
    final (fillColor, strokeColor) = _colorsForCategory(category);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (category == NodeCategory.logic) {
      final diamond = Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
      canvas.drawPath(diamond, fillPaint);
      canvas.drawPath(diamond, strokePaint);
    } else {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
    }

    final textColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.name,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 20);

    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );

    if (warningNodeIds.contains(node.id)) {
      final badgeCenter = Offset(rect.right - 8, rect.top + 8);
      canvas.drawCircle(
        badgeCenter,
        7,
        Paint()..color = const Color(0xFFF59E0B),
      );
      final bangPainter = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bangPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - bangPainter.width / 2,
          badgeCenter.dy - bangPainter.height / 2,
        ),
      );
    }
  }

  (Color fill, Color stroke) _colorsForCategory(NodeCategory category) {
    if (isDark) {
      return switch (category) {
        NodeCategory.trigger => (
            const Color(0xFF1B3B2B),
            const Color(0xFF66BB6A),
          ),
        NodeCategory.action => (
            const Color(0xFF1A2F4A),
            const Color(0xFF64B5F6),
          ),
        NodeCategory.logic => (
            const Color(0xFF3D3115),
            const Color(0xFFFFD54F),
          ),
        NodeCategory.output => (
            const Color(0xFF2A2D34),
            const Color(0xFF9CA3AF),
          ),
      };
    }

    return switch (category) {
      NodeCategory.trigger => (
          const Color(0xFFD5E8D4),
          const Color(0xFF82B366),
        ),
      NodeCategory.action => (
          const Color(0xFFDAE8FC),
          const Color(0xFF6C8EBF),
        ),
      NodeCategory.logic => (
          const Color(0xFFFFF2CC),
          const Color(0xFFD6B656),
        ),
      NodeCategory.output => (
          const Color(0xFFF5F5F5),
          const Color(0xFF666666),
        ),
    };
  }

  @override
  bool shouldRepaint(covariant WorkflowCanvasPainter oldDelegate) {
    return oldDelegate.model != model ||
        oldDelegate.layout.canvasSize != layout.canvasSize ||
        oldDelegate.warningNodeIds != warningNodeIds ||
        oldDelegate.isDark != isDark;
  }
}
