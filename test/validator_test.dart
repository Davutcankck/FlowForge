import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/export/node_name_deduplicator.dart';
import 'package:flowforge/core/export/validator.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';

WorkflowModel _model({
  required List<WorkflowNode> nodes,
  List<WorkflowEdge> edges = const [],
}) {
  return WorkflowModel(
    id: 'wf-1',
    name: 'Test Workflow',
    nodes: nodes,
    edges: edges,
    updatedAt: DateTime.utc(2026),
  );
}

void main() {
  const validator = Validator();

  group('Validator (V-01..V-05)', () {
    test('geçerli ve tüm zorunlu parametreleri dolu akışta 0 bulgu döner', () {
      final model = _model(
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'order-hook', 'httpMethod': 'POST'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://api.example.com', 'method': 'GET'},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
        ],
      );

      final issues = validator.validate(model);
      expect(issues, isEmpty);
      expect(issues.canExport, isTrue);
      expect(issues.hasErrors, isFalse);
      expect(issues.hasWarnings, isFalse);
      expect(issues.requiresConfirmation, isFalse);
    });

    test('V-01: trigger yoksa Hata döner ve dışa aktarma engellenir', () {
      final model = _model(
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://api.example.com'},
            position: Offset.zero,
          ),
        ],
      );

      final issues = validator.validate(model);
      expect(
        issues.any(
          (i) => i.code == 'V-01' && i.severity == ValidationSeverity.error,
        ),
        isTrue,
      );
      expect(issues.hasErrors, isTrue);
      expect(issues.canExport, isFalse);
    });

    test('V-02: tetikleyiciye bağlı olmayan düğüm Uyarı verir, devam edilebilir',
        () {
      final model = _model(
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'my-hook'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [],
      );

      final issues = validator.validate(model);
      expect(
        issues.any(
          (i) =>
              i.code == 'V-02' &&
              i.severity == ValidationSeverity.warning &&
              i.nodeId == '2',
        ),
        isTrue,
      );
      expect(issues.canExport, isTrue);
      expect(issues.requiresConfirmation, isTrue);
    });

    test('V-03: döngü (cycle) varsa Hata döner ve dışa aktarma engellenir', () {
      final model = _model(
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'my-hook'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://example.com'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '3',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
          WorkflowEdge(fromId: '2', toId: '3', outputIndex: 0),
          WorkflowEdge(fromId: '3', toId: '2', outputIndex: 0),
        ],
      );

      final issues = validator.validate(model);
      expect(
        issues.any(
          (i) => i.code == 'V-03' && i.severity == ValidationSeverity.error,
        ),
        isTrue,
      );
      expect(issues.canExport, isFalse);
    });

    test('V-04: HTTP URL veya Webhook path boşsa Uyarı döner', () {
      final model = _model(
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': '   '},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': ''},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
        ],
      );

      final issues = validator.validate(model);
      final v04 = issues.where((i) => i.code == 'V-04').toList();
      expect(v04.length, 2);
      expect(v04.every((i) => i.severity == ValidationSeverity.warning), isTrue);
      expect(issues.canExport, isTrue);
      expect(issues.requiresConfirmation, isTrue);
    });

    test('V-05: tekrar eden node adları info olarak raporlanır, dışa aktarmayı engellemez',
        () {
      final model = _model(
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '3',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
          WorkflowEdge(fromId: '2', toId: '3', outputIndex: 0),
        ],
      );

      final issues = validator.validate(model);
      expect(issues.length, 1);
      expect(issues.first.code, 'V-05');
      expect(issues.first.severity, ValidationSeverity.info);
      expect(issues.first.nodeId, '3');
      expect(issues.canExport, isTrue);
      expect(issues.requiresConfirmation, isFalse);

      final fixed = applyUniqueNames(model);
      expect(fixed.nodes.map((n) => n.name).toList(), [
        'Webhook',
        'Telegram',
        'Telegram1',
      ]);
    });

    test('ValidationIssue value semantics (==, hashCode, toString)', () {
      const a = ValidationIssue(
        code: 'V-01',
        severity: ValidationSeverity.error,
        message: 'msg',
      );
      const b = ValidationIssue(
        code: 'V-01',
        severity: ValidationSeverity.error,
        message: 'msg',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('V-01'));
    });
  });
}
