import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/features/wizard/flow_controller.dart';
import 'package:flowforge/main.dart';

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
    ],
    child: const FlowForgeApp(),
  );
}

Future<void> _tapOption(WidgetTester tester, String labelKey) async {
  final finder = find.byKey(Key('option_$labelKey'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('WizardScreen Widget Testleri', () {
    testWidgets(
      'girişten başlayıp SDD Bölüm 7 senaryosunu uçtan uca tamamlar ve canlı node sayısını gösterir',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Giriş ekranı
        expect(find.byKey(const Key('start_new_workflow_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('start_new_workflow_button')));
        await tester.pumpAndSettle();

        // Başlangıçta 0 node -> "Önizleme"
        expect(find.text('Önizleme'), findsOneWidget);

        // 1. Webhook
        await _tapOption(tester, 'trigger.webhook');
        expect(find.text('Önizleme (1)'), findsOneWidget);

        // 2. HTTP Request
        await _tapOption(tester, 'action.httpRequest');
        expect(find.text('Önizleme (2)'), findsOneWidget);

        // 3. IF
        await _tapOption(tester, 'cond.if');
        expect(find.text('Önizleme (3)'), findsOneWidget);
        expect(find.text('Koşul: DOĞRU dalı'), findsOneWidget);

        // 4. True dalı -> Google Sheets -> dalı tamamla
        await _tapOption(tester, 'out.googleSheets');
        expect(find.text('Önizleme (4)'), findsOneWidget);
        await _tapOption(tester, 'branch.end');
        expect(find.text('Koşul: YANLIŞ dalı'), findsOneWidget);

        // 5. False dalı -> Telegram -> dalı tamamla
        await _tapOption(tester, 'out.telegram');
        expect(find.text('Önizleme (5)'), findsOneWidget);
        await _tapOption(tester, 'branch.end');

        // Akış tamamlandı
        expect(find.text('Akış Tasarımı Tamamlandı'), findsOneWidget);
        expect(find.byKey(const Key('completed_open_preview_button')), findsOneWidget);
      },
    );

    testWidgets('geri al (undo) butonu bir önceki soruya döner ve node sayısını geri alır',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.tap(find.byKey(const Key('start_new_workflow_button')));
      await tester.pumpAndSettle();

      await _tapOption(tester, 'trigger.webhook');
      expect(find.text('Önizleme (1)'), findsOneWidget);

      await _tapOption(tester, 'action.httpRequest');
      expect(find.text('Önizleme (2)'), findsOneWidget);

      // Undo -> 1 node'a düşer ve q_action sorusuna döner
      await tester.tap(find.byKey(const Key('wizard_undo_button')));
      await tester.pumpAndSettle();

      expect(find.text('Önizleme (1)'), findsOneWidget);
      expect(find.byKey(const Key('option_action.httpRequest')), findsOneWidget);
    });

    testWidgets('boş akışta Önizleme açıldığında empty state güvenle gösterilir',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.tap(find.byKey(const Key('start_new_workflow_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wizard_preview_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preview_empty_state_title')), findsOneWidget);
    });

    testWidgets('schedule tetikleyicisinde respondToWebhook seçeneği gizlenir',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.tap(find.byKey(const Key('start_new_workflow_button')));
      await tester.pumpAndSettle();

      await _tapOption(tester, 'trigger.schedule');
      await _tapOption(tester, 'action.none');
      await _tapOption(tester, 'cond.none');

      expect(find.byKey(const Key('option_out.telegram')), findsOneWidget);
      expect(
        find.byKey(const Key('option_out.respondToWebhook')),
        findsNothing,
      );
    });
  });
}
