import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/features/preview/preview_screen.dart';
import 'package:flowforge/features/wizard/flow_controller.dart';
import 'fixtures/answer_key_helper.dart';
import 'fixtures/scenarios.dart';

void main() {
  testWidgets(
    'canvas_tap: tuvalde düğüme dokununca NodeParamSheet açılır, boş alana dokununca açılmaz',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        ],
      );
      addTearDown(container.dispose);

      // Senaryo A'yı motor üzerinden kur
      final ctrl = container.read(flowControllerProvider.notifier);
      ctrl.startNewWorkflow();
      for (final label in scenarioLinear.answers) {
        final opts = container.read(availableOptionsProvider);
        ctrl.answer(answerKey(opts, label));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PreviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final model = container.read(effectiveWorkflowProvider);
      final layout = container.read(layoutResultProvider);
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('preview_interactive_viewer')),
      );
      final matrix = viewer.transformationController!.value;
      final viewerTopLeft = tester
          .getTopLeft(find.byKey(const Key('preview_interactive_viewer')));

      // Boş alana dokunma (sol üst köşe) -> sheet açılmamalı
      await tester.tapAt(
        viewerTopLeft + MatrixUtils.transformPoint(matrix, const Offset(5, 5)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('save_node_params_button')), findsNothing);

      // Webhook düğümüne dokunma -> NodeParamSheet açılmalı
      final webhook = model.nodes.firstWhere((n) => n.templateKey == 'webhook');
      final webhookCenter = layout.sceneRects[webhook.id]!.center;
      await tester.tapAt(
        viewerTopLeft + MatrixUtils.transformPoint(matrix, webhookCenter),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('param_field_path')), findsOneWidget);
    },
  );
}
