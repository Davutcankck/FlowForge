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

  group('AutoLayout', () {
    test('boş model aynı şekilde döner', () {
      final empty = WorkflowModel.empty(gen: SequentialIdGenerator());
      final result = layout.apply(empty);
      expect(result.nodes, isEmpty);
      expect(result.edges, isEmpty);
    });

    test('lineer akış: x = derinlik * 250, y = 0 ve immutability korunur', () {
      final model = _buildScenarioModel(scenarioLinear);
      final laidOut = layout.apply(model);

      // Orijinal model değişmemeli
      expect(model.nodes.every((n) => n.position == Offset.zero), isTrue);

      expect(laidOut.nodes[0].position, const Offset(0, 0));
      expect(laidOut.nodes[1].position, const Offset(250, 0));
      expect(laidOut.nodes[2].position, const Offset(500, 0));
    });

    test('SDD Bölüm 7 IF dallanma: true -60, false +60 kaydırılır', () {
      final model = _buildScenarioModel(scenarioIfBranch);
      final laidOut = layout.apply(model);

      expect(laidOut.nodes[0].templateKey, 'webhook');
      expect(laidOut.nodes[0].position, const Offset(0, 0));

      expect(laidOut.nodes[1].templateKey, 'httpRequest');
      expect(laidOut.nodes[1].position, const Offset(250, 0));

      expect(laidOut.nodes[2].templateKey, 'if');
      expect(laidOut.nodes[2].position, const Offset(500, 0));

      expect(laidOut.nodes[3].templateKey, 'googleSheets');
      expect(laidOut.nodes[3].position, const Offset(750, -60));

      expect(laidOut.nodes[4].templateKey, 'telegram');
      expect(laidOut.nodes[4].position, const Offset(750, 60));
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

      final laidOut = layout.apply(model);
      final positions = laidOut.nodes.map((n) => n.position).toSet();
      expect(positions.length, laidOut.nodes.length);
      expect(laidOut.nodeById('n3')!.position, const Offset(500, -60));
      expect(laidOut.nodeById('n4')!.position, const Offset(500, 60));
      expect(laidOut.nodeById('n5')!.position, const Offset(750, -120));
      expect(laidOut.nodeById('n6')!.position, const Offset(750, 0));
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

      final laidOut = layout.apply(cyclic);
      expect(laidOut.nodeById('a')!.position, const Offset(0, 0));
      expect(laidOut.nodeById('b')!.position, const Offset(250, 0));
      expect(laidOut.nodeById('c')!.position, const Offset(500, 0));
    });

    test('triggersız saf döngü ve bağlantısız (orphan) düğümler deterministik yerleşir',
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

      final laidOut = layout.apply(model);
      // Tüm düğümler benzersiz ve sonlu pozisyon almalı
      final posSet = laidOut.nodes.map((n) => n.position).toSet();
      expect(posSet.length, laidOut.nodes.length);
      expect(laidOut.nodeById('n1')!.position, const Offset(0, 0));
      expect(laidOut.nodeById('n2')!.position, const Offset(250, 0));
      expect(laidOut.nodeById('orphan1')!.position, const Offset(0, 120));
      expect(laidOut.nodeById('orphanCycleA')!.position, const Offset(0, 240));
      expect(laidOut.nodeById('orphanCycleB')!.position, const Offset(250, 240));
    });
  });
}
