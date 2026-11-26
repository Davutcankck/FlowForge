import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/layout/auto_layout.dart';
import 'package:flowforge/core/layout/hit_tester.dart';
import 'package:flowforge/core/models/workflow_node.dart';

void main() {
  const hitTester = CanvasHitTester();

  const nodeA = WorkflowNode(
    id: 'a',
    templateKey: 'webhook',
    name: 'Webhook',
    parameters: {},
    position: Offset.zero,
  );
  const nodeB = WorkflowNode(
    id: 'b',
    templateKey: 'httpRequest',
    name: 'HTTP Request',
    parameters: {},
    position: Offset.zero,
  );

  group('CanvasHitTester', () {
    test('1. düğüm içi tıklama ilgili düğümü döndürür', () {
      final layout = LayoutResult(
        nodeRects: const {'a': Rect.fromLTWH(0, 0, 140, 60)},
        originOffset: const Offset(80, 80),
        canvasSize: const Size(420, 320),
      );

      final hit = hitTester.hitTest(
        scenePoint: const Offset(150, 110),
        nodes: const [nodeA],
        layout: layout,
        scale: 1.0,
      );
      expect(hit?.id, 'a');
    });

    test('2. boş alana tıklama null döndürür', () {
      final layout = LayoutResult(
        nodeRects: const {'a': Rect.fromLTWH(0, 0, 140, 60)},
        originOffset: const Offset(80, 80),
        canvasSize: const Size(420, 320),
      );

      final hit = hitTester.hitTest(
        scenePoint: const Offset(10, 10),
        nodes: const [nodeA],
        layout: layout,
        scale: 1.0,
      );
      expect(hit, isNull);
    });

    test('3. z-sırası: üst üste binen düğümlerde son çizilen düğüm kazanır', () {
      final layout = LayoutResult(
        nodeRects: const {
          'a': Rect.fromLTWH(0, 0, 140, 60),
          'b': Rect.fromLTWH(20, 10, 140, 60),
        },
        originOffset: const Offset(80, 80),
        canvasSize: const Size(420, 320),
      );

      // Kesişim noktası: sceneRects['a'] = (80..220, 80..140), sceneRects['b'] = (100..240, 90..150)
      final hit = hitTester.hitTest(
        scenePoint: const Offset(120, 110),
        nodes: const [nodeA, nodeB],
        layout: layout,
        scale: 1.0,
      );
      expect(hit?.id, 'b');
    });

    test('4. küçük ölçekte (scale 0.4, kısa kenar 60) slop = 25 ile kenar dışı yakalanır',
        () {
      const rect = Rect.fromLTWH(0, 0, 140, 60);
      expect(CanvasHitTester.computeSlop(rect, 0.4), closeTo(25.0, 0.0001));

      final layout = LayoutResult(
        nodeRects: const {'a': rect},
        originOffset: const Offset(80, 80),
        canvasSize: const Size(420, 320),
      );
      // sceneRect top = 80; slop = 25 -> y = 60 (20 birim dışarıda, 25 içinde) yakalanmalı
      final hit = hitTester.hitTest(
        scenePoint: const Offset(150, 60),
        nodes: const [nodeA],
        layout: layout,
        scale: 0.4,
      );
      expect(hit?.id, 'a');

      // y = 50 (30 birim dışarıda, 25 dışında) null olmalı
      final miss = hitTester.hitTest(
        scenePoint: const Offset(150, 50),
        nodes: const [nodeA],
        layout: layout,
        scale: 0.4,
      );
      expect(miss, isNull);
    });

    test('5. büyük ölçekte (scale 1.5, kısa kenar 60) slop = 0 olduğundan kenar dışı null döner',
        () {
      const rect = Rect.fromLTWH(0, 0, 140, 60);
      expect(CanvasHitTester.computeSlop(rect, 1.5), 0.0);

      final layout = LayoutResult(
        nodeRects: const {'a': rect},
        originOffset: const Offset(80, 80),
        canvasSize: const Size(420, 320),
      );
      // sceneRect top = 80; 1 birim dışarıda (y = 79) slop = 0 olduğu için null dönmeli
      final miss = hitTester.hitTest(
        scenePoint: const Offset(150, 79),
        nodes: const [nodeA],
        layout: layout,
        scale: 1.5,
      );
      expect(miss, isNull);
    });
  });
}
