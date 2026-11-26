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

WorkflowModel _buildScenarioB() {
  final engine = FlowEngine(gen: SequentialIdGenerator());
  var state = engine.start();
  for (final label in scenarioIfBranch.answers) {
    final options = engine.availableOptions(state);
    state = engine.answer(state, answerKey(options, label));
  }
  return const AutoLayout().apply(state.effectiveModel);
}

String _normalizeLineEndings(String text) =>
    text.replaceAll('\r\n', '\n').trim();

void main() {
  group('Golden Export Tests (SDD Bölüm 7 — Senaryo B)', () {
    test('n8n JSON çıktısı golden dosya ile birebir eşleşir', () {
      final model = _buildScenarioB();
      final actual = _normalizeLineEndings(const N8nExporter().export(model));
      final expected = _normalizeLineEndings(
        File('test/goldens/scenario_b_n8n.json').readAsStringSync(),
      );

      expect(actual, expected);
    });

    test('draw.io XML çıktısı golden dosya ile birebir eşleşir', () {
      final model = _buildScenarioB();
      final actual = _normalizeLineEndings(const DrawioExporter().export(model));
      final expected = _normalizeLineEndings(
        File('test/goldens/scenario_b.drawio').readAsStringSync(),
      );

      expect(actual, expected);
    });
  });
}
