import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:flowforge/core/export/drawio_exporter.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';

void main() {
  const exporter = DrawioExporter();

  group('DrawioExporter', () {
    test('zorunlu id="0" ve id="1" kök hücrelerini ve kategori stillerini üretir',
        () {
      final model = WorkflowModel(
        id: 'wf-cats',
        name: 'All Categories',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {},
            position: Offset(0, 0),
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {},
            position: Offset(250, 0),
          ),
          WorkflowNode(
            id: '3',
            templateKey: 'if',
            name: 'IF',
            parameters: {},
            position: Offset(500, 0),
          ),
          WorkflowNode(
            id: '4',
            templateKey: 'respondToWebhook',
            name: 'Respond to Webhook',
            parameters: {},
            position: Offset(750, -60),
          ),
          WorkflowNode(
            id: '5',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset(750, 60),
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
          WorkflowEdge(fromId: '2', toId: '3', outputIndex: 0),
          WorkflowEdge(fromId: '3', toId: '4', outputIndex: 0),
          WorkflowEdge(fromId: '3', toId: '5', outputIndex: 1),
        ],
      );

      final xmlStr = exporter.export(model);
      final doc = XmlDocument.parse(xmlStr);

      final root = doc.findAllElements('root').single;
      final cells = root.findElements('mxCell').toList();

      // İlk iki hücre zorunlu kök hücreleri olmalı
      expect(cells[0].getAttribute('id'), '0');
      expect(cells[1].getAttribute('id'), '1');
      expect(cells[1].getAttribute('parent'), '0');

      // Kategori stilleri
      final webhookCell =
          cells.firstWhere((c) => c.getAttribute('id') == 'node_1');
      expect(webhookCell.getAttribute('style'), contains('#d5e8d4')); // yeşil

      final httpCell =
          cells.firstWhere((c) => c.getAttribute('id') == 'node_2');
      expect(httpCell.getAttribute('style'), contains('#dae8fc')); // mavi

      final ifCell = cells.firstWhere((c) => c.getAttribute('id') == 'node_3');
      expect(ifCell.getAttribute('style'), contains('rhombus')); // eşkenar dörtgen
      expect(ifCell.getAttribute('style'), contains('#fff2cc')); // sarı

      final outCell = cells.firstWhere((c) => c.getAttribute('id') == 'node_4');
      expect(outCell.getAttribute('style'), contains('#f5f5f5')); // gri

      // IF çıkış kenar etiketleri
      final trueEdge = cells.firstWhere(
        (c) =>
            c.getAttribute('source') == 'node_3' &&
            c.getAttribute('target') == 'node_4',
      );
      expect(trueEdge.getAttribute('value'), 'true');

      final falseEdge = cells.firstWhere(
        (c) =>
            c.getAttribute('source') == 'node_3' &&
            c.getAttribute('target') == 'node_5',
      );
      expect(falseEdge.getAttribute('value'), 'false');
    });

    test('& < > " özel karakterlerini XML içinde otomatik escape eder', () {
      final model = WorkflowModel(
        id: 'wf-esc',
        name: 'A & B <Test> "Quoted"',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Hook & <Check> "1"',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [],
      );

      final xmlStr = exporter.export(model);
      // Ham XML özniteliklerinde zorunlu XML 1.0 kaçışları (&, <, ") uygulanmış olmalı
      expect(xmlStr, contains('&amp;'));
      expect(xmlStr, contains('&lt;'));
      expect(xmlStr, contains('&quot;'));

      // Geri parse edildiğinde & < > " karakterlerinin tamamı bozulmadan korunmalı
      final doc = XmlDocument.parse(xmlStr);
      final diagram = doc.findAllElements('diagram').single;
      expect(diagram.getAttribute('name'), 'A & B <Test> "Quoted"');

      final nodeCell = doc
          .findAllElements('mxCell')
          .firstWhere((c) => c.getAttribute('id') == 'node_1');
      expect(nodeCell.getAttribute('value'), 'Hook & <Check> "1"');
    });
  });
}
