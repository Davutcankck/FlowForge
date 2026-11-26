import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/features/preview/preview_screen.dart';
import 'package:flowforge/features/wizard/flow_controller.dart';
import 'package:flowforge/main.dart';

Future<void> _tapOption(WidgetTester tester, String labelKey) async {
  final finder = find.byKey(Key('option_$labelKey'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _pumpCompletedScenarioToPreview(
  WidgetTester tester,
) async {
  final container = ProviderContainer(
    overrides: [
      idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FlowForgeApp(),
    ),
  );

  await tester.tap(find.byKey(const Key('start_new_workflow_button')));
  await tester.pumpAndSettle();

  await _tapOption(tester, 'trigger.webhook');
  await _tapOption(tester, 'action.httpRequest');
  await _tapOption(tester, 'cond.if');
  await _tapOption(tester, 'out.googleSheets');
  await _tapOption(tester, 'branch.end');
  await _tapOption(tester, 'out.telegram');
  await _tapOption(tester, 'branch.end');

  await tester.tap(find.byKey(const Key('completed_open_preview_button')));
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('PreviewScreen, NodeParamSheet ve ExportSummaryScreen Widget Testleri',
      () {
    testWidgets(
      'tuvalde HTTP Request düğümüne dokunup URL düzenleyince V-04 uyarısı kalkar',
      (tester) async {
        final container = await _pumpCompletedScenarioToPreview(tester);

        expect(find.byType(PreviewScreen), findsOneWidget);
        expect(
          find.byKey(const Key('preview_interactive_viewer')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('preview_workflow_canvas')),
          findsOneWidget,
        );

        // Başlangıçta HTTP Request url boş olduğu için V-04 uyarısı var
        expect(
          container.read(validationIssuesProvider).any((i) => i.code == 'V-04'),
          isTrue,
        );

        // HTTP Request node merkezini InteractiveViewer dönüşümüyle hesapla ve dokun
        final model = container.read(effectiveWorkflowProvider);
        final layout = container.read(layoutResultProvider);
        final httpNode =
            model.nodes.firstWhere((n) => n.templateKey == 'httpRequest');
        final httpCenter = layout.sceneRects[httpNode.id]!.center;

        final viewer = tester.widget<InteractiveViewer>(
          find.byKey(const Key('preview_interactive_viewer')),
        );
        final matrix = viewer.transformationController!.value;
        final transformed = MatrixUtils.transformPoint(matrix, httpCenter);
        final viewerTopLeft = tester
            .getTopLeft(find.byKey(const Key('preview_interactive_viewer')));
        await tester.tapAt(viewerTopLeft + transformed);
        await tester.pumpAndSettle();

        // NodeParamSheet açılmış olmalı
        expect(find.byKey(const Key('param_field_url')), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('param_field_url')),
          'https://api.example.com/orders',
        );
        await tester.tap(find.byKey(const Key('save_node_params_button')));
        await tester.pumpAndSettle();

        // Parametre güncellenmiş ve V-04 uyarısı kalkmış olmalı
        final updatedModel = container.read(effectiveWorkflowProvider);
        final updatedHttp =
            updatedModel.nodes.firstWhere((n) => n.id == httpNode.id);
        expect(updatedHttp.parameters['url'], 'https://api.example.com/orders');
        expect(container.read(validationIssuesProvider), isEmpty);

        // Doğrulama özetinde "temiz" banner'ı görünmeli
        await tester.tap(find.byKey(const Key('preview_export_summary_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('validation_banner_clean')), findsOneWidget);
        expect(find.byKey(const Key('export_n8n_preview')), findsOneWidget);
      },
    );

    testWidgets(
      'boş parametreli IF düğümüne dokunulduğunda bilgilendirme ve özel parametre ekleme çalışır',
      (tester) async {
        // Büyük ekran boyutu vererek IF düğümünün görünür alanda olmasını sağla
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = await _pumpCompletedScenarioToPreview(tester);
        final model = container.read(effectiveWorkflowProvider);
        final layout = container.read(layoutResultProvider);
        final ifNode = model.nodes.firstWhere((n) => n.templateKey == 'if');
        final ifCenter = layout.sceneRects[ifNode.id]!.center;

        final viewer = tester.widget<InteractiveViewer>(
          find.byKey(const Key('preview_interactive_viewer')),
        );
        final transformed = MatrixUtils.transformPoint(
          viewer.transformationController!.value,
          ifCenter,
        );
        final viewerTopLeft = tester
            .getTopLeft(find.byKey(const Key('preview_interactive_viewer')));
        await tester.tapAt(viewerTopLeft + transformed);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('empty_params_info')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('custom_param_key_field')),
          'condition',
        );
        await tester.enterText(
          find.byKey(const Key('custom_param_value_field')),
          'status == 200',
        );
        await tester.tap(find.byKey(const Key('add_custom_param_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('save_node_params_button')));
        await tester.pumpAndSettle();

        final updatedIf = container
            .read(effectiveWorkflowProvider)
            .nodes
            .firstWhere((n) => n.id == ifNode.id);
        expect(updatedIf.parameters['condition'], 'status == 200');
      },
    );

    testWidgets(
      'workflow adı düzenlenebilir ve uyarılı akışta uyarı bannerı görünür',
      (tester) async {
        await _pumpCompletedScenarioToPreview(tester);

        await tester.tap(find.byKey(const Key('preview_rename_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('rename_workflow_field')),
          'Sipariş Akışı',
        );
        await tester.tap(find.byKey(const Key('confirm_rename_workflow_button')));
        await tester.pumpAndSettle();

        expect(find.text('Sipariş Akışı'), findsOneWidget);

        // HTTP URL hâlâ boş -> ExportSummaryScreen'de uyarı banner'ı görünmeli
        await tester.tap(find.byKey(const Key('preview_export_summary_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('validation_banner_warning')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export_n8n_preview')), findsOneWidget);
      },
    );

    testWidgets(
      'fitToScreen dar dikey ekranda ölçeği [0.3, 1.0] aralığında sığdırır, varsayılan ad Yeni Workflow ve ipucu kapatılabilir',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpCompletedScenarioToPreview(tester);

        // Varsayılan ad "Yeni Workflow"
        expect(find.text('Yeni Workflow'), findsOneWidget);

        // fitToScreen ölçeği 0.3..1.0 aralığında ve 1.0'dan küçük olmalı
        final viewer = tester.widget<InteractiveViewer>(
          find.byKey(const Key('preview_interactive_viewer')),
        );
        final scale = viewer.transformationController!.value.getMaxScaleOnAxis();
        expect(scale, greaterThanOrEqualTo(0.3));
        expect(scale, lessThan(1.0));

        // İpucu bandı başlangıçta görünür, kapatılınca gizlenir
        expect(find.byKey(const Key('preview_hint_banner')), findsOneWidget);
        await tester.tap(find.byKey(const Key('dismiss_preview_hint_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('preview_hint_banner')), findsNothing);
      },
    );
  });
}
