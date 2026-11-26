import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:flowforge/core/export/drawio_exporter.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';

WorkflowModel _allCategoriesModel() {
  return WorkflowModel(
    id: 'wf-cats',
    name: 'All Categories',
    updatedAt: DateTime.utc(2026),
    nodes: const [
      WorkflowNode(
        id: '1',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {},
        position: Offset(999, 999),
      ),
      WorkflowNode(
        id: '2',
        templateKey: 'httpRequest',
        name: 'HTTP Request',
        parameters: {},
        position: Offset.zero,
      ),
      WorkflowNode(
        id: '3',
        templateKey: 'if',
        name: 'IF',
        parameters: {},
        position: Offset.zero,
      ),
      WorkflowNode(
        id: '4',
        templateKey: 'respondToWebhook',
        name: 'Respond to Webhook',
        parameters: {},
        position: Offset.zero,
      ),
      WorkflowNode(
        id: '5',
        templateKey: 'telegram',
        name: 'Telegram',
        parameters: {},
        position: Offset.zero,
      ),
    ],
    edges: const [
      WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
      WorkflowEdge(fromId: '2', toId: '3', outputIndex: 0),
      WorkflowEdge(fromId: '3', toId: '4', outputIndex: 0),
      WorkflowEdge(fromId: '3', toId: '5', outputIndex: 1),
    ],
  );
}

void main() {
  const exporter = DrawioExporter();

  group('DrawioExporter', () {
    test('1. zorunlu id="0" ve id="1" kök hücreleri parent="0" ile ilk iki sıradadır',
        () {
      final doc = XmlDocument.parse(exporter.export(_allCategoriesModel()));
      final cells = doc.findAllElements('root').single.findElements('mxCell').toList();

      expect(cells[0].getAttribute('id'), '0');
      expect(cells[1].getAttribute('id'), '1');
      expect(cells[1].getAttribute('parent'), '0');

      // Tüm vertex ve edge hücreleri parent="1" taşımalı
      for (final cell in cells.skip(2)) {
        expect(cell.getAttribute('parent'), '1');
      }
    });

    test('2. hücre kimlikleri SDD biçiminde n_<id> ve e_<sıra> üretilir', () {
      final doc = XmlDocument.parse(exporter.export(_allCategoriesModel()));
      final cells = doc.findAllElements('mxCell').toList();

      expect(cells.any((c) => c.getAttribute('id') == 'n_1'), isTrue);
      expect(cells.any((c) => c.getAttribute('id') == 'n_3'), isTrue);
      expect(cells.any((c) => c.getAttribute('id') == 'e_0'), isTrue);
      expect(cells.any((c) => c.getAttribute('id') == 'e_3'), isTrue);
    });

    test('3. tüm düğümler (IF dahil) LayoutResult.nodeRects üzerinden 140x60 boyut alır',
        () {
      final doc = XmlDocument.parse(exporter.export(_allCategoriesModel()));
      final vertexCells = doc
          .findAllElements('mxCell')
          .where((c) => c.getAttribute('vertex') == '1')
          .toList();

      expect(vertexCells.length, 5);
      for (final cell in vertexCells) {
        final geom = cell.findElements('mxGeometry').single;
        expect(geom.getAttribute('width'), '140');
        expect(geom.getAttribute('height'), '60');
      }

      // Webhook node.position = (999, 999) olsa da LayoutResult'tan (0, 0) almalı
      final webhookGeom = vertexCells
          .firstWhere((c) => c.getAttribute('id') == 'n_1')
          .findElements('mxGeometry')
          .single;
      expect(webhookGeom.getAttribute('x'), '0');
      expect(webhookGeom.getAttribute('y'), '0');
    });

    test('4. dört kategori stili (trigger yeşil, action mavi, logic rhombus sarı, output gri)',
        () {
      final doc = XmlDocument.parse(exporter.export(_allCategoriesModel()));
      final cells = doc.findAllElements('mxCell').toList();

      final webhookCell = cells.firstWhere((c) => c.getAttribute('id') == 'n_1');
      expect(webhookCell.getAttribute('style'), contains('#d5e8d4'));

      final httpCell = cells.firstWhere((c) => c.getAttribute('id') == 'n_2');
      expect(httpCell.getAttribute('style'), contains('#dae8fc'));

      final ifCell = cells.firstWhere((c) => c.getAttribute('id') == 'n_3');
      expect(ifCell.getAttribute('style'), contains('rhombus'));
      expect(ifCell.getAttribute('style'), contains('#fff2cc'));

      final outCell = cells.firstWhere((c) => c.getAttribute('id') == 'n_4');
      expect(outCell.getAttribute('style'), contains('#f5f5f5'));
    });

    test('5. IF çıkış kenarları true / false olarak etiketlenir', () {
      final doc = XmlDocument.parse(exporter.export(_allCategoriesModel()));
      final cells = doc.findAllElements('mxCell').toList();

      final trueEdge = cells.firstWhere(
        (c) =>
            c.getAttribute('source') == 'n_3' &&
            c.getAttribute('target') == 'n_4',
      );
      expect(trueEdge.getAttribute('value'), 'true');

      final falseEdge = cells.firstWhere(
        (c) =>
            c.getAttribute('source') == 'n_3' &&
            c.getAttribute('target') == 'n_5',
      );
      expect(falseEdge.getAttribute('value'), 'false');
    });

    test('6. & < > " özel karakterleri XML içinde escape edilip bozulmadan parse edilir',
        () {
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
      expect(xmlStr, contains('&amp;'));
      expect(xmlStr, contains('&lt;'));
      expect(xmlStr, contains('&quot;'));

      final doc = XmlDocument.parse(xmlStr);
      final diagram = doc.findAllElements('diagram').single;
      expect(diagram.getAttribute('name'), 'A & B <Test> "Quoted"');

      final nodeCell = doc
          .findAllElements('mxCell')
          .firstWhere((c) => c.getAttribute('id') == 'n_1');
      expect(nodeCell.getAttribute('value'), 'Hook & <Check> "1"');
    });

    test('7. üretilen XML çıktısı \\r (CRLF) içermez', () {
      final xmlStr = exporter.export(_allCategoriesModel());
      expect(xmlStr.contains('\r'), isFalse);
    });
  });
}
