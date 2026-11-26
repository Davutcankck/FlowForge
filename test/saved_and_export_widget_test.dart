import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';
import 'package:flowforge/features/export/export_summary_screen.dart';
import 'package:flowforge/features/preview/preview_screen.dart';
import 'package:flowforge/features/saved/saved_workflows_controller.dart';
import 'package:flowforge/features/settings/settings_controller.dart';
import 'package:flowforge/features/wizard/flow_controller.dart';
import 'package:flowforge/main.dart';
import 'package:flowforge/services/export_share_service.dart';
import 'package:flowforge/services/storage_service.dart';

class _FakeExportShareService extends ExportShareService {
  _FakeExportShareService({this.shouldFailShare = false});

  final bool shouldFailShare;
  String? lastCopiedText;
  String? lastSharedFileName;
  String? lastSharedContent;

  @override
  Future<void> copyToClipboard(String text) async {
    lastCopiedText = text;
  }

  @override
  Future<void> shareTextAsFile({
    required String content,
    required String fileName,
    required String subject,
  }) async {
    if (shouldFailShare) {
      throw const FileSystemException('Disk dolu');
    }
    lastSharedFileName = fileName;
    lastSharedContent = content;
  }
}

WorkflowModel _workflowWithWarning({String id = 'wf-warn'}) {
  return WorkflowModel(
    id: id,
    name: 'Sipariş Akışı',
    updatedAt: DateTime.utc(2026, 6, 1, 14, 0),
    nodes: const [
      WorkflowNode(
        id: 'n1',
        templateKey: 'webhook',
        name: 'Webhook',
        parameters: {'path': 'orders', 'httpMethod': 'POST'},
        position: Offset.zero,
      ),
      WorkflowNode(
        id: 'n2',
        templateKey: 'httpRequest',
        name: 'HTTP Request',
        // url boş -> V-04 uyarısı üretir
        parameters: {'url': '', 'method': 'GET'},
        position: Offset(250, 0),
      ),
    ],
    edges: const [
      WorkflowEdge(fromId: 'n1', toId: 'n2', outputIndex: 0),
    ],
  );
}

WorkflowModel _workflowWithError() {
  return WorkflowModel(
    id: 'wf-err',
    name: 'Triggersız Akış',
    updatedAt: DateTime.utc(2026, 6, 1, 14, 0),
    nodes: const [
      WorkflowNode(
        id: 'n1',
        templateKey: 'telegram',
        name: 'Telegram',
        parameters: {},
        position: Offset.zero,
      ),
    ],
    edges: const [],
  );
}

void main() {
  group('SavedWorkflowsScreen Widget Testleri', () {
    testWidgets(
      'kayıtlı akışları ve bozuk kayıt uyarısını gösterir; tek dokunuşla PreviewScreen açar, yeniden adlandırır ve siler',
      (tester) async {
        final storage = InMemoryStorageService(
          initialRawEntries: {'corrupt-key': '{bad-json'},
        );
        final wf = _workflowWithWarning(id: 'wf-1');
        await storage.save(wf);

        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FlowForgeApp(),
          ),
        );

        // Bozuk kayıt banner'ı ve kayıtlı kart görünmeli
        expect(find.byKey(const Key('corrupted_records_banner')), findsOneWidget);
        expect(find.byKey(const Key('saved_workflow_card_wf-1')), findsOneWidget);
        expect(find.text('Sipariş Akışı'), findsOneWidget);

        // Karta dokununca doğrudan PreviewScreen açılmalı ve aynı ID korunmalı
        await tester.tap(find.byKey(const Key('saved_workflow_card_wf-1')));
        await tester.pumpAndSettle();
        expect(find.byType(PreviewScreen), findsOneWidget);
        expect(container.read(flowControllerProvider).model.id, 'wf-1');

        // Ana ekrana geri dön
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Yeniden adlandır
        await tester.tap(find.byKey(const Key('saved_workflow_menu_wf-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yeniden Adlandır'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('saved_rename_field')),
          'Yeni Sipariş Akışı',
        );
        await tester.tap(find.byKey(const Key('confirm_saved_rename_button')));
        await tester.pumpAndSettle();
        expect(find.text('Yeni Sipariş Akışı'), findsOneWidget);

        // Onaylı silme
        await tester.tap(find.byKey(const Key('saved_workflow_menu_wf-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sil'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_delete_workflow_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('saved_empty_state_title')), findsOneWidget);
      },
    );

    testWidgets(
      'Hive başlatma hatasında storage_init_failed_banner gösterilir ve uygulama çökmez',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            storageInitFailedProvider.overrideWith((ref) => true),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FlowForgeApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('storage_init_failed_banner')),
          findsOneWidget,
        );
      },
    );
  });

  group('ExportSummaryScreen Aksiyon & Hata Yönetimi Widget Testleri', () {
    testWidgets(
      'uyarılı akışta "Yine de aktar" onayı ile panoya kopyalar ve aynı ID ile kaydeder',
      (tester) async {
        final storage = InMemoryStorageService();
        final fakeShare = _FakeExportShareService();

        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            exportShareServiceProvider.overrideWithValue(fakeShare),
          ],
        );
        addTearDown(container.dispose);

        final wf = _workflowWithWarning(id: 'wf-save-1');
        container.read(flowControllerProvider.notifier).loadSavedWorkflow(wf);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ExportSummaryScreen()),
          ),
        );

        expect(
          find.byKey(const Key('validation_banner_warning')),
          findsOneWidget,
        );

        // Kaydet -> aynı ID ile storage'a yazılmalı
        await tester.tap(find.byKey(const Key('export_save_button')));
        await tester.pumpAndSettle();
        expect(storage.loadAll().workflows.single.id, 'wf-save-1');

        // Panoya Kopyala -> önce uyarı onay diyalogu açılmalı
        await tester.tap(find.byKey(const Key('export_copy_json_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('confirm_export_with_warnings_button')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('confirm_export_with_warnings_button')),
        );
        await tester.pumpAndSettle();

        expect(fakeShare.lastCopiedText, isNotNull);
        expect(fakeShare.lastCopiedText, contains('"n8n-nodes-base.webhook"'));
      },
    );

    testWidgets(
      'dosya yazma/paylaşma hatasında fallback diyalogu açılır ve JSON panoya kopyalanabilir',
      (tester) async {
        final fakeShare = _FakeExportShareService(shouldFailShare: true);

        final container = ProviderContainer(
          overrides: [
            exportShareServiceProvider.overrideWithValue(fakeShare),
          ],
        );
        addTearDown(container.dispose);

        final wf = _workflowWithWarning(id: 'wf-fail');
        container.read(flowControllerProvider.notifier).loadSavedWorkflow(wf);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ExportSummaryScreen()),
          ),
        );

        await tester.tap(find.byKey(const Key('export_share_n8n_button')));
        await tester.pumpAndSettle();

        // Uyarı onayını geç
        await tester.tap(
          find.byKey(const Key('confirm_export_with_warnings_button')),
        );
        await tester.pumpAndSettle();

        // Dosya yazma hatası diyalogu ve fallback butonu görünmeli
        expect(find.byKey(const Key('file_write_error_dialog')), findsOneWidget);
        await tester.tap(find.byKey(const Key('fallback_copy_json_button')));
        await tester.pumpAndSettle();

        expect(fakeShare.lastCopiedText, isNotNull);
        expect(fakeShare.lastCopiedText, contains('"Sipariş Akışı"'));
      },
    );

    testWidgets('hata seviyesinde dışa aktarma ve kopyalama butonları devre dışıdır',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(flowControllerProvider.notifier)
          .loadSavedWorkflow(_workflowWithError());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ExportSummaryScreen()),
        ),
      );

      expect(find.byKey(const Key('validation_banner_error')), findsOneWidget);
      expect(find.byKey(const Key('export_blocked_message')), findsOneWidget);

      final shareBtn = tester.widget<FilledButton>(
        find.byKey(const Key('export_share_n8n_button')),
      );
      expect(shareBtn.onPressed, isNull);

      final copyBtn = tester.widget<OutlinedButton>(
        find.byKey(const Key('export_copy_json_button')),
      );
      expect(copyBtn.onPressed, isNull);
    });
  });
}
