import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/export/n8n_exporter.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';

void main() {
  const exporter = N8nExporter();

  group('N8nExporter', () {
    test('SDD 5.3 üst düzey anahtar sırası ve varsayılan alanlar doğru üretilir',
        () {
      final model = WorkflowModel(
        id: 'wf-schema',
        name: 'Schema Check',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook', 'httpMethod': 'POST'},
            position: Offset.zero,
          ),
        ],
        edges: const [],
      );

      final map = exporter.toMap(model);
      expect(map.keys.toList(), [
        'name',
        'nodes',
        'connections',
        'active',
        'settings',
        'pinData',
        'meta',
      ]);
      expect(map['active'], isFalse);
      expect(map['settings'], {'executionOrder': 'v1'});
      expect(map['pinData'], <String, dynamic>{});
      expect(map['meta'], {'instanceId': ''});
    });

    test('tekrar eden node adlarını deterministik tekilleştirir ve connections adla anahtarlanır',
        () {
      final model = WorkflowModel(
        id: 'wf-dup',
        name: 'Duplicate Names',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: 'id-1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook', 'httpMethod': 'POST'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'id-2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://a.test', 'method': 'GET'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'id-3',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://b.test', 'method': 'POST'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'id-4',
            templateKey: 'httpRequest',
            name: 'HTTP Request1',
            parameters: {'url': 'https://c.test', 'method': 'GET'},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: 'id-1', toId: 'id-2', outputIndex: 0),
          WorkflowEdge(fromId: 'id-2', toId: 'id-3', outputIndex: 0),
          WorkflowEdge(fromId: 'id-3', toId: 'id-4', outputIndex: 0),
        ],
      );

      final decoded = jsonDecode(exporter.export(model)) as Map<String, dynamic>;
      final nodes = decoded['nodes'] as List<dynamic>;
      final names = nodes.map((n) => (n as Map)['name']).toList();

      expect(names, [
        'Webhook',
        'HTTP Request',
        'HTTP Request2',
        'HTTP Request1',
      ]);

      final connections = decoded['connections'] as Map<String, dynamic>;
      expect(connections.keys.toList(), [
        'Webhook',
        'HTTP Request',
        'HTTP Request2',
      ]);
      expect(connections.containsKey('id-1'), isFalse);
      expect(
        connections['HTTP Request']['main'][0][0]['node'],
        'HTTP Request2',
      );
      expect(
        connections['HTTP Request2']['main'][0][0]['node'],
        'HTTP Request1',
      );
    });

    test('IF düğümünde yalnızca false (outputIndex: 1) bağlıysa main [[], [...]] sırasını korur',
        () {
      final model = WorkflowModel(
        id: 'wf-if-false-only',
        name: 'False Only IF',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook', 'httpMethod': 'POST'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'if',
            name: 'IF',
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
          WorkflowEdge(fromId: '2', toId: '3', outputIndex: 1),
        ],
      );

      final map = exporter.toMap(model);
      final connections = map['connections'] as Map<String, dynamic>;
      final ifMain = connections['IF']['main'] as List<dynamic>;

      expect(ifMain.length, 2);
      expect(ifMain[0], isEmpty);
      expect(ifMain[1], [
        {'node': 'Telegram', 'type': 'main', 'index': 0},
      ]);
    });

    test('pozisyonlar node.position yerine LayoutResult.nodeRects üzerinden [x, y] yazılır',
        () {
      final model = WorkflowModel(
        id: 'wf-pos',
        name: 'Pos',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'p'},
            // Kasıtlı alakasız position — exporter LayoutResult.nodeRects'i okumalı
            position: Offset(999, 999),
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'telegram',
            name: 'Telegram',
            parameters: {},
            position: Offset(888, 888),
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
        ],
      );

      final map = exporter.toMap(model);
      final nodes = map['nodes'] as List<dynamic>;
      expect((nodes[0] as Map)['position'], [0, 0]);
      expect((nodes[1] as Map)['position'], [250, 0]);
    });

    test('bilinmeyen şablon için StateError fırlatır', () {
      final invalid = WorkflowModel(
        id: 'wf-bad',
        name: 'Bad',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'unknown_template',
            name: 'Unknown',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [],
      );
      expect(() => exporter.export(invalid), throwsA(isA<StateError>()));
    });

    test('respondToWebhook var/yok/kullanıcı override durumunda webhook responseMode kuralı',
        () {
      // 1. respondToWebhook var -> responseMode: 'responseNode' eklenir
      final withRespond = WorkflowModel(
        id: 'wf-r1',
        name: 'With Respond',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook', 'httpMethod': 'POST'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'respondToWebhook',
            name: 'Respond to Webhook',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
        ],
      );
      final mapWith = exporter.toMap(withRespond);
      final webhookWith =
          (mapWith['nodes'] as List).first as Map<String, dynamic>;
      expect(webhookWith['parameters']['responseMode'], 'responseNode');

      // 2. respondToWebhook yok -> responseMode eklenmez
      final withoutRespond = WorkflowModel(
        id: 'wf-r2',
        name: 'Without Respond',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook', 'httpMethod': 'POST'},
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
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
        ],
      );
      final mapWithout = exporter.toMap(withoutRespond);
      final webhookWithout =
          (mapWithout['nodes'] as List).first as Map<String, dynamic>;
      expect(
        (webhookWithout['parameters'] as Map).containsKey('responseMode'),
        isFalse,
      );

      // 3. Kullanıcı elle responseMode vermişse ezilmez
      final userOverride = WorkflowModel(
        id: 'wf-r3',
        name: 'User Override',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {
              'path': 'hook',
              'httpMethod': 'POST',
              'responseMode': 'lastNode',
            },
            position: Offset.zero,
          ),
          WorkflowNode(
            id: '2',
            templateKey: 'respondToWebhook',
            name: 'Respond to Webhook',
            parameters: {},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: '1', toId: '2', outputIndex: 0),
        ],
      );
      final mapOverride = exporter.toMap(userOverride);
      final webhookOverride =
          (mapOverride['nodes'] as List).first as Map<String, dynamic>;
      expect(webhookOverride['parameters']['responseMode'], 'lastNode');
    });

    test('dışa aktarılan JSON çıktısı \\r (CRLF) içermez', () {
      final model = WorkflowModel(
        id: 'wf-lf',
        name: 'LF Check',
        updatedAt: DateTime.utc(2026),
        nodes: const [
          WorkflowNode(
            id: '1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'hook'},
            position: Offset.zero,
          ),
        ],
        edges: const [],
      );
      final jsonStr = exporter.export(model);
      expect(jsonStr.contains('\r'), isFalse);
    });
  });
}
