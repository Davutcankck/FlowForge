import 'dart:ui';

import 'package:test/test.dart';

import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/core/models/workflow_node.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';

void main() {
  group('WorkflowModel immutable state', () {
    test('addNode returns new model and does not mutate original', () {
      final gen = SequentialIdGenerator();
      final original = WorkflowModel.empty(gen: gen);

      final added = original.addNode(
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'my-hook'},
        position: const Offset(0, 0),
        gen: gen,
      );

      expect(original.nodes, isEmpty);
      expect(added.nodes.length, 1);
      expect(added.nodes.first.templateKey, 'webhook');
      expect(added.nodes.first.name, 'Webhook');
      expect(added.nodes.first.parameters, {'path': 'my-hook'});
    });

    test('copyWith creates independent copy', () {
      final gen = SequentialIdGenerator();
      final model = WorkflowModel.empty(gen: gen).addNode(
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {},
        position: const Offset(0, 0),
        gen: gen,
      );

      final copied = model.copyWith(name: 'Renamed');

      expect(copied.name, 'Renamed');
      expect(model.name, 'Yeni Workflow');
      expect(copied.nodes.length, model.nodes.length);
      expect(identical(copied.nodes, model.nodes), isFalse);
    });

    test('toJson / fromJson round-trip preserves model', () {
      final gen = SequentialIdGenerator();
      final model = WorkflowModel.empty(gen: gen)
          .addNode(
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'x'},
            position: const Offset(0, 0),
            gen: gen,
          )
          .addNode(
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://api.example.com'},
            position: const Offset(250, 0),
            gen: gen,
          );

      // addEdge returns new model; chain immutably
      final withEdge = model.addEdge(
        fromId: model.nodes.first.id,
        toId: model.nodes.last.id,
        outputIndex: 0,
      );

      final json = withEdge.toJson();
      final restored = WorkflowModel.fromJson(json);

      expect(restored.toJson(), json);
      expect(restored.edges.length, 1);
      expect(restored.edges.first.fromId, model.nodes.first.id);
      expect(restored.edges.first.toId, model.nodes.last.id);
      expect(restored.edges.first.outputIndex, 0);
    });

    test('nodeById returns correct node or null', () {
      final gen = SequentialIdGenerator();
      final model = WorkflowModel.empty(gen: gen).addNode(
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {},
        position: const Offset(0, 0),
        gen: gen,
      );

      expect(model.nodeById(model.nodes.first.id)?.templateKey, 'webhook');
      expect(model.nodeById('nonexistent'), isNull);
    });

    test('removeNode returns model without the node', () {
      final gen = SequentialIdGenerator();
      final model = WorkflowModel.empty(gen: gen).addNode(
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {},
        position: const Offset(0, 0),
        gen: gen,
      );

      final removed = model.removeNode(model.nodes.first.id);
      expect(removed.nodes, isEmpty);
    });

    test('nodes and edges are unmodifiable (removeLast throws UnsupportedError)', () {
      final gen = SequentialIdGenerator();
      final model = WorkflowModel.empty(gen: gen)
          .addNode(
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {},
            position: const Offset(0, 0),
            gen: gen,
          )
          .addEdge(fromId: 'id-1', toId: 'id-2', outputIndex: 0);

      expect(() => model.nodes.removeLast(), throwsUnsupportedError);
      expect(() => model.edges.removeLast(), throwsUnsupportedError);
    });
  });

  group('WorkflowNode value semantics', () {
    test('== and hashCode work for equal nodes', () {
      const n1 = WorkflowNode(
        id: 'id-1',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'x'},
        position: Offset(0, 0),
      );
      const n2 = WorkflowNode(
        id: 'id-1',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'x'},
        position: Offset(0, 0),
      );
      const n3 = WorkflowNode(
        id: 'id-2',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'x'},
        position: Offset(0, 0),
      );

      expect(n1, n2);
      expect(n1.hashCode, n2.hashCode);
      expect(n1 == n3, isFalse);
    });

    test('copyWith updates only provided fields', () {
      const node = WorkflowNode(
        id: 'id-1',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'x'},
        position: Offset(0, 0),
      );
      final updated = node.copyWith(name: 'Updated Webhook');

      expect(updated.name, 'Updated Webhook');
      expect(updated.id, 'id-1');
      expect(updated.templateKey, 'webhook');
      expect(updated.parameters, {'path': 'x'});
    });
  });

  group('WorkflowEdge value semantics', () {
    test('== and hashCode work for equal edges', () {
      const e1 = WorkflowEdge(fromId: 'a', toId: 'b', outputIndex: 0);
      const e2 = WorkflowEdge(fromId: 'a', toId: 'b', outputIndex: 0);
      const e3 = WorkflowEdge(fromId: 'a', toId: 'b', outputIndex: 1);

      expect(e1, e2);
      expect(e1.hashCode, e2.hashCode);
      expect(e1 == e3, isFalse);
    });
  });
}
