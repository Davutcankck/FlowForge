import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/export/drawio_exporter.dart';
import 'package:flowforge/core/export/n8n_exporter.dart';
import 'package:flowforge/core/layout/auto_layout.dart';
import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/questions/flow_engine.dart';
import 'fixtures/answer_key_helper.dart';
import 'fixtures/scenarios.dart';

WorkflowModel _buildScenario(Scenario scenario) {
  final engine = FlowEngine(gen: SequentialIdGenerator());
  var state = engine.start();
  for (final label in scenario.answers) {
    final options = engine.availableOptions(state);
    state = engine.answer(state, answerKey(options, label));
  }
  return state.effectiveModel.copyWith(name: 'FlowForge Workflow');
}

String _readGoldenLf(String path) {
  final raw = File(path).readAsStringSync();
  return raw.replaceAll('\r\n', '\n').trim();
}

void main() {
  const layout = AutoLayout();
  const n8nExporter = N8nExporter();
  const drawioExporter = DrawioExporter();

  group('Golden Export Tests (Linear + IF Branch)', () {
    test('linear n8n JSON çıktısı golden dosya ile birebir eşleşir ve \\r içermez',
        () {
      final model = _buildScenario(scenarioLinear);
      final actual = n8nExporter.export(model, layout: layout.compute(model));
      expect(actual.contains('\r'), isFalse);

      final expected = _readGoldenLf('test/goldens/linear.n8n.json');
      expect(actual.trim(), expected);
    });

    test('linear draw.io XML çıktısı golden dosya ile birebir eşleşir ve \\r içermez',
        () {
      final model = _buildScenario(scenarioLinear);
      final actual =
          drawioExporter.export(model, layout: layout.compute(model));
      expect(actual.contains('\r'), isFalse);

      final expected = _readGoldenLf('test/goldens/linear.drawio');
      expect(actual.trim(), expected);
    });

    test('if_branch n8n JSON çıktısı golden dosya ile birebir eşleşir ve \\r içermez',
        () {
      final model = _buildScenario(scenarioIfBranch);
      final actual = n8nExporter.export(model, layout: layout.compute(model));
      expect(actual.contains('\r'), isFalse);

      final expected = _readGoldenLf('test/goldens/if_branch.n8n.json');
      expect(actual.trim(), expected);
    });

    test('if_branch draw.io XML çıktısı golden dosya ile birebir eşleşir ve \\r içermez',
        () {
      final model = _buildScenario(scenarioIfBranch);
      final actual =
          drawioExporter.export(model, layout: layout.compute(model));
      expect(actual.contains('\r'), isFalse);

      final expected = _readGoldenLf('test/goldens/if_branch.drawio');
      expect(actual.trim(), expected);
    });
  });
}
