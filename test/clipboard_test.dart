import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/export/n8n_exporter.dart';
import 'package:flowforge/core/layout/auto_layout.dart';
import 'package:flowforge/core/models/workflow_edge.dart';
import 'package:flowforge/core/models/workflow_model.dart';
import 'package:flowforge/core/models/workflow_node.dart';
import 'package:flowforge/features/export/export_summary_screen.dart';
import 'package:flowforge/features/wizard/flow_controller.dart';

void main() {
  testWidgets(
    'SystemChannels.platform mock: Clipboard.setData çağrılır ve metin n8n JSON çıktısı ile birebir aynıdır',
    (tester) async {
      String? capturedClipboardText;
      var setDataCallCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          setDataCallCount++;
          final args = call.arguments as Map<dynamic, dynamic>;
          capturedClipboardText = args['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final model = WorkflowModel(
        id: 'wf-clip',
        name: 'Clipboard Test',
        updatedAt: DateTime.utc(2026, 6, 1),
        nodes: const [
          WorkflowNode(
            id: 'n1',
            templateKey: 'webhook',
            name: 'Webhook',
            parameters: {'path': 'clip-hook', 'httpMethod': 'POST'},
            position: Offset.zero,
          ),
          WorkflowNode(
            id: 'n2',
            templateKey: 'httpRequest',
            name: 'HTTP Request',
            parameters: {'url': 'https://api.example.com', 'method': 'GET'},
            position: Offset.zero,
          ),
        ],
        edges: const [
          WorkflowEdge(fromId: 'n1', toId: 'n2', outputIndex: 0),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(flowControllerProvider.notifier).loadSavedWorkflow(model);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ExportSummaryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export_copy_json_button')));
      await tester.pumpAndSettle();

      final expectedJson = const N8nExporter().export(
        model,
        layout: const AutoLayout().compute(model),
      );

      expect(setDataCallCount, 1);
      expect(capturedClipboardText, expectedJson);
    },
  );
}
