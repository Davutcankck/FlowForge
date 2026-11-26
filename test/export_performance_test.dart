import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/export/drawio_exporter.dart';
import 'package:flowforge/core/export/n8n_exporter.dart';
import 'package:flowforge/core/export/validator.dart';
import 'package:flowforge/core/layout/auto_layout.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';

WorkflowModel _build50NodeWorkflow() {
  final nodes = <WorkflowNode>[
    const WorkflowNode(
      id: 'node-0',
      templateKey: 'webhook',
      name: 'Webhook',
      parameters: {'path': 'perf-hook', 'httpMethod': 'POST'},
      position: Offset.zero,
    ),
  ];
  final edges = <WorkflowEdge>[];

  for (var i = 1; i < 50; i++) {
    nodes.add(
      WorkflowNode(
        id: 'node-$i',
        templateKey: i % 5 == 0 ? 'if' : 'httpRequest',
        name: i % 5 == 0 ? 'IF' : 'HTTP Request',
        parameters: i % 5 == 0
            ? const {}
            : {'url': 'https://api.example.com/step/$i', 'method': 'GET'},
        position: Offset.zero,
      ),
    );
    edges.add(
      WorkflowEdge(
        fromId: 'node-${i - 1}',
        toId: 'node-$i',
        outputIndex: 0,
      ),
    );
  }

  return WorkflowModel(
    id: 'wf-perf-50',
    name: 'Performance 50 Nodes',
    nodes: nodes,
    edges: edges,
    updatedAt: DateTime.utc(2026),
  );
}

void main() {
  test('NFR-03: 50 node\'luk akışta layout + doğrulama + her iki dışa aktarma < 500 ms',
      () {
    const layout = AutoLayout();
    const validator = Validator();
    const n8nExporter = N8nExporter();
    const drawioExporter = DrawioExporter();

    final model = _build50NodeWorkflow();
    expect(model.nodes.length, 50);

    final n8nWatch = Stopwatch()..start();
    final laidOutForN8n = layout.apply(model);
    final issues = validator.validate(laidOutForN8n);
    final n8nJson = n8nExporter.export(laidOutForN8n);
    n8nWatch.stop();

    expect(issues.canExport, isTrue);
    expect(n8nJson, isNotEmpty);
    expect(
      n8nWatch.elapsedMilliseconds,
      lessThan(500),
      reason: 'n8n dışa aktarma 500 ms sınırını aştı: ${n8nWatch.elapsedMilliseconds} ms',
    );

    final drawioWatch = Stopwatch()..start();
    final laidOutForDrawio = layout.apply(model);
    final drawioXml = drawioExporter.export(laidOutForDrawio);
    drawioWatch.stop();

    expect(drawioXml, isNotEmpty);
    expect(
      drawioWatch.elapsedMilliseconds,
      lessThan(500),
      reason:
          'draw.io dışa aktarma 500 ms sınırını aştı: ${drawioWatch.elapsedMilliseconds} ms',
    );
  });
}
