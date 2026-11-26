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
    'preview_golden: IF dallanmalı önizleme ekranı golden görselle eşleşir',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 700);
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

      final ctrl = container.read(flowControllerProvider.notifier);
      ctrl.startNewWorkflow();
      for (final label in scenarioIfBranch.answers) {
        final opts = container.read(availableOptionsProvider);
        ctrl.answer(answerKey(opts, label));
      }
      ctrl.renameWorkflow('FlowForge Workflow');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true),
            home: const PreviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PreviewScreen),
        matchesGoldenFile('goldens/preview_if_branch.png'),
      );
    },
  );
}
