import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';
import 'package:flowforge/services/export_share_service.dart';
import 'package:flowforge/services/storage_service.dart';

WorkflowModel _sampleWorkflow({
  required String id,
  required String name,
  required DateTime updatedAt,
}) {
  return WorkflowModel(
    id: id,
    name: name,
    updatedAt: updatedAt,
    nodes: const [
      WorkflowNode(
        id: 'n1',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'hook', 'httpMethod': 'POST'},
        position: Offset.zero,
      ),
      WorkflowNode(
        id: 'n2',
        templateKey: 'telegram',
        name: 'Telegram',
        parameters: {},
        position: Offset(250, 0),
      ),
    ],
    edges: const [
      WorkflowEdge(fromId: 'n1', toId: 'n2', outputIndex: 0),
    ],
  );
}

void main() {
  group('StorageService (Hive)', () {
    late Directory tempDir;
    late Box<String> box;
    late StorageService storage;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('flowforge_hive_test_');
      Hive.init(tempDir.path);
      box = await Hive.openBox<String>(StorageService.boxName);
      storage = StorageService(box);
    });

    tearDown(() async {
      if (box.isOpen) {
        await box.close();
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('save ve loadAll yeniden eskiye sıralar ve schemaVersion: 1 yazar',
        () async {
      final older = _sampleWorkflow(
        id: 'wf-old',
        name: 'Eski Akış',
        updatedAt: DateTime.utc(2026, 1, 1, 10, 0),
      );
      final newer = _sampleWorkflow(
        id: 'wf-new',
        name: 'Yeni Akış',
        updatedAt: DateTime.utc(2026, 1, 2, 12, 0),
      );

      await storage.save(older);
      await storage.save(newer);

      // Ham Hive kaydında schemaVersion == 1 doğrula
      final rawJson =
          jsonDecode(box.get('wf-new')!) as Map<String, dynamic>;
      expect(rawJson['schemaVersion'], 1);

      final result = storage.loadAll();
      expect(result.hasCorrupted, isFalse);
      expect(result.workflows.map((w) => w.id).toList(), ['wf-new', 'wf-old']);
    });

    test('kutu kapatılıp yeniden açıldığında veriler kalıcı olarak durur',
        () async {
      final wf = _sampleWorkflow(
        id: 'wf-persist',
        name: 'Kalıcı Akış',
        updatedAt: DateTime.utc(2026, 5, 10, 15, 30),
      );
      await storage.save(wf);
      await box.close();

      // Aynı dizinden kutuyu yeniden aç
      box = await Hive.openBox<String>(StorageService.boxName);
      storage = StorageService(box);

      final result = storage.loadAll();
      expect(result.workflows.length, 1);
      expect(result.workflows.first.id, 'wf-persist');
      expect(result.workflows.first.name, 'Kalıcı Akış');
      expect(result.workflows.first.schemaVersion, 1);
      expect(result.workflows.first.nodes.length, 2);
    });

    test('rename ve delete kayıtları doğru günceller ve siler', () async {
      final wf = _sampleWorkflow(
        id: 'wf-edit',
        name: 'İlk Ad',
        updatedAt: DateTime.utc(2026, 3, 1),
      );
      await storage.save(wf);

      final renamed = await storage.rename('wf-edit', 'Güncel Ad');
      expect(renamed, isNotNull);
      expect(renamed!.name, 'Güncel Ad');
      expect(storage.loadAll().workflows.first.name, 'Güncel Ad');

      await storage.delete('wf-edit');
      expect(storage.loadAll().workflows, isEmpty);
    });

    test('bozuk JSON kaydı çökmeden atlanır ve corruptedIds içinde raporlanır',
        () async {
      final valid = _sampleWorkflow(
        id: 'wf-good',
        name: 'Sağlam Akış',
        updatedAt: DateTime.utc(2026, 4, 1),
      );
      await storage.save(valid);
      await box.put('wf-corrupt-1', '{bozuk-json');
      await box.put('wf-corrupt-2', '{"id":"missing-fields"}');

      final result = storage.loadAll();
      expect(result.workflows.length, 1);
      expect(result.workflows.first.id, 'wf-good');
      expect(result.hasCorrupted, isTrue);
      expect(
        result.corruptedIds,
        containsAll(['wf-corrupt-1', 'wf-corrupt-2']),
      );
    });
  });

  group('sanitizeFileName', () {
    test('Türkçe karakterleri, boşlukları ve / karakterini güvenli hale getirir',
        () {
      expect(
        sanitizeFileName('Sipariş Akışı / Üretim #1', extension: '.json'),
        'siparis_akisi_uretim_1.json',
      );
      expect(
        sanitizeFileName('ÇĞİÖŞÜ çğıöşü', extension: 'drawio'),
        'cgiosu_cgiosu.drawio',
      );
      expect(
        sanitizeFileName('   ///   ', extension: '.json'),
        'flowforge_workflow.json',
      );
    });
  });
}
