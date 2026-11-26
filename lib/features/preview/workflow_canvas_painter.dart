import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/catalog/node_catalog.dart';
import '../../core/catalog/node_category.dart';
import '../../core/models/workflow_model.dart';
import '../../core/models/workflow_node.dart';
import 'canvas_layout_geometry.dart';

/// Akış düğümlerini ve yönlü bağlantıları çizen [CustomPainter] (SDD 6.1).
class WorkflowCanvasPainter extends CustomPainter {
  WorkflowCanvasPainter({
    required this.model,
    required this.geometry,
    required this.warningNodeIds,
    required this.isDark,
  });

  final WorkflowModel model;
  final CanvasLayoutGeometry geometry;
  final Set<String> warningNodeIds;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (model.nodes.isEmpty) return;

    final nodeById = <String, WorkflowNode>{
      for (final node in model.nodes) node.id: node,
    };

    // 1. Önce bağlantıları (edges) çiz
    for (final edge in model.edges) {
      final fromRect = geometry.rectFor(edge.fromId);
      final toRect = geometry.rectFor(edge.toId);
      final fromNode = nodeById[edge.fromId];
      if (fromRect == null || toRect == null || fromNode == null) continue;

      final start = Offset(fromRect.right, fromRect.center.dy);
      final end = Offset(toRect.left, toRect.center.dy);

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
      final rect = geometry.rectFor(node.id);
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
    final edgeColor = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A);
    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final midX = (start.dx + end.dx) / 2;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);

    // Ok ucu (arrowhead)
    const arrowLength = 10.0;
    const arrowAngle = math.pi / 6;
    final angle = math.atan2(end.dy - start.dy, end.dx - midX);
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

    // IF dal etiketi ("true" / "false")
    if (label != null) {
      final labelCenter = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 - 10,
      );
      final isTrue = label == 'true';
      final pillFill = isTrue
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFEBEE);
      final pillText = isTrue
          ? const Color(0xFF2E7D32)
          : const Color(0xFFC62828);

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

    // Düğüm adı
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.name,
        style: const TextStyle(
          color: Color(0xFF1F2937),
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

    // V-04 uyarı rozeti
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
        oldDelegate.warningNodeIds != warningNodeIds ||
        oldDelegate.isDark != isDark;
  }
}
