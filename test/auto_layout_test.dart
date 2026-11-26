import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/layout/auto_layout.dart';
import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';
import 'package:flowforge/core/questions/flow_engine.dart';
import 'fixtures/answer_key_helper.dart';
import 'fixtures/scenarios.dart';

WorkflowModel _buildScenarioModel(Scenario scenario) {
  final engine = FlowEngine(gen: SequentialIdGenerator());
  var state = engine.start();
  for (final label in scenario.answers) {
    final options = engine.availableOptions(state);
    state = engine.answer(state, answerKey(options, label));
  }
  return state.effectiveModel;
}

void main() {
  const layout = AutoLayout();

  group('AutoLayout (LayoutResult)', () {
    test('boş model boş nodeRects ve minimum tuval boyutu döner', () {
      final empty = WorkflowModel.empty(gen: SequentialIdGenerator());
      final result = layout.compute(empty);
      expect(result.nodeRects, isEmpty);
      expect(result.sceneRects, isEmpty);
      expect(result.canvasSize.width, greaterThanOrEqualTo(420));
      expect(result.canvasSize.height, greaterThanOrEqualTo(320));
    });

    test('lineer akış: x = derinlik * 250, y = 0, tüm düğümler 140x60', () {
      final model = _buildScenarioModel(scenarioLinear);
      final result = layout.compute(model);

      expect(result.nodeRects[model.nodes[0].id], const Rect.fromLTWH(0, 0, 140, 60));
      expect(result.nodeRects[model.nodes[1].id], const Rect.fromLTWH(250, 0, 140, 60));
      expect(result.nodeRects[model.nodes[2].id], const Rect.fromLTWH(500, 0, 140, 60));
    });

    test('SDD Bölüm 7 IF dallanma: true -60, false +60 ve sceneRects = nodeRects + originOffset',
        () {
      final model = _buildScenarioModel(scenarioIfBranch);
      final result = layout.compute(model);

      expect(result.nodeRects[model.nodes[0].id]!.topLeft, const Offset(0, 0));
      expect(result.nodeRects[model.nodes[1].id]!.topLeft, const Offset(250, 0));
      expect(result.nodeRects[model.nodes[2].id]!.topLeft, const Offset(500, 0));
      expect(result.nodeRects[model.nodes[2].id]!.size, const Size(140, 60));
      expect(result.nodeRects[model.nodes[3].id]!.topLeft, const Offset(750, -60));
      expect(result.nodeRects[model.nodes[4].id]!.topLeft, const Offset(750, 60));

      // sceneRects pozitif koordinatlara taşınmış olmalı
      for (final entry in result.nodeRects.entries) {
        expect(
          result.sceneRects[entry.key],
          entry.value.shift(result.originOffset),
        );
      }
    });

    test('iç içe IF dallanmasında çakışma olmaz', () {
      final model = WorkflowModel(
        id: 'wf-nested',
        name: 'Nested IF',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: 'n1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n2',
            templateKey: 'if',
            name: 'IF',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n3',
            templateKey: 'if',
            name: 'IF',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n4',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n5',
            templateKey: 'gmail',
            name: 'Gmail',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n6',
            templateKey: 'googleSheets',
            name: 'Google Sheets',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: 'n1', toId: 'n2', outputIndex: 0),
          WorkflowEdge(fromId: 'n2', toId: 'n3', outputIndex: 0),
          WorkflowEdge(fromId: 'n2', toId: 'n4', outputIndex: 1),
          WorkflowEdge(fromId: 'n3', toId: 'n5', outputIndex: 0),
          WorkflowEdge(fromId: 'n3', toId: 'n6', outputIndex: 1),
        ],
      );

      final result = layout.compute(model);
      final positions = result.nodeRects.values.map((r) => r.topLeft).toSet();
      expect(positions.length, model.nodes.length);
      expect(result.nodeRects['n3']!.topLeft, const Offset(500, -60));
      expect(result.nodeRects['n4']!.topLeft, const Offset(500, 60));
      expect(result.nodeRects['n5']!.topLeft, const Offset(750, -120));
      expect(result.nodeRects['n6']!.topLeft, const Offset(750, 0));
    });

    test('döngülü (cycle) akışta sonsuz döngüye girmeden deterministik yerleşir',
        () {
      final cyclic = WorkflowModel(
        id: 'wf-cycle',
        name: 'Cyclic',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: 'a',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'b',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'c',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: 'a', toId: 'b', outputIndex: 0),
          WorkflowEdge(fromId: 'b', toId: 'c', outputIndex: 0),
          WorkflowEdge(fromId: 'c', toId: 'a', outputIndex: 0),
        ],
      );

      final result = layout.compute(cyclic);
      expect(result.nodeRects['a']!.topLeft, const Offset(0, 0));
      expect(result.nodeRects['b']!.topLeft, const Offset(250, 0));
      expect(result.nodeRects['c']!.topLeft, const Offset(500, 0));
    });

    test('bağlantısız (orphan) düğümler ve ayrık döngüler deterministik yerleşir',
        () {
      final model = WorkflowModel(
        id: 'wf-orphan',
        name: 'Orphan',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: 'n1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'orphan1',
            templateKey: 'gmail',
            name: 'Gmail',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'orphanCycleA',
            templateKey: 'set',
            name: 'Set A',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'orphanCycleB',
            templateKey: 'telegram',
            name: 'Telegram B',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: 'n1', toId: 'n2', outputIndex: 0),
          WorkflowEdge(
            fromId: 'orphanCycleA',
            toId: 'orphanCycleB',
            outputIndex: 0,
          ),
          WorkflowEdge(
            fromId: 'orphanCycleB',
            toId: 'orphanCycleA',
            outputIndex: 0,
          ),
        ],
      );

      final result = layout.compute(model);
      final posSet = result.nodeRects.values.map((r) => r.topLeft).toSet();
      expect(posSet.length, model.nodes.length);
      expect(result.nodeRects['n1']!.topLeft, const Offset(0, 0));
      expect(result.nodeRects['n2']!.topLeft, const Offset(250, 0));
      expect(result.nodeRects['orphan1']!.topLeft, const Offset(0, 120));
      expect(result.nodeRects['orphanCycleA']!.topLeft, const Offset(0, 240));
      expect(result.nodeRects['orphanCycleB']!.topLeft, const Offset(250, 240));
    });
  });
}
