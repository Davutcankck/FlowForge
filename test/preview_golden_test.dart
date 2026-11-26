import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/features/preview/preview_screen.dart';
import 'package:flowforge/features/wizard/flow_controller.dart';
import 'fixtures/answer_key_helper.dart';
import 'fixtures/scenarios.dart';

Future<void> _pumpIfBranchPreview(
  WidgetTester tester, {
  required Brightness brightness,
}) async {
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: brightness,
          ),
        ),
        home: const PreviewScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'preview_golden: IF dallanmalı açık tema önizleme ekranı golden görselle eşleşir',
    (tester) async {
      await _pumpIfBranchPreview(tester, brightness: Brightness.light);
      await expectLater(
        find.byType(PreviewScreen),
        matchesGoldenFile('goldens/preview_if_branch.png'),
      );
    },
  );

  testWidgets(
    'preview_golden_dark: IF dallanmalı koyu tema önizleme ekranı golden görselle eşleşir',
    (tester) async {
      await _pumpIfBranchPreview(tester, brightness: Brightness.dark);
      await expectLater(
        find.byType(PreviewScreen),
        matchesGoldenFile('goldens/preview_if_branch_dark.png'),
      );
    },
  );
}
