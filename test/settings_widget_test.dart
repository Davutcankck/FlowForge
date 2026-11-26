import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/l10n/app_strings.dart';
import 'package:flowforge/features/settings/settings_controller.dart';
import 'package:flowforge/main.dart';
import 'package:flowforge/services/settings_service.dart';

void main() {
  group('SettingsScreen Widget Testleri', () {
    testWidgets(
      'dil TR -> EN ve tema Sistem -> Koyu değiştirildiğinde arayüz anında güncellenir',
      (tester) async {
        final settingsStorage = InMemorySettingsService(
          initialLang: AppLang.tr,
          initialThemeMode: ThemeMode.system,
        );

        final container = ProviderContainer(
          overrides: [
            settingsServiceProvider.overrideWithValue(settingsStorage),
            defaultAppLangProvider.overrideWithValue(AppLang.tr),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const FlowForgeApp(),
          ),
        );

        // Başlangıçta Türkçe
        expect(find.text('Yeni Workflow Başlat'), findsOneWidget);

        // Ayarlar ekranını aç
        await tester.tap(find.byKey(const Key('open_settings_button')));
        await tester.pumpAndSettle();
        expect(find.text('Ayarlar'), findsOneWidget);

        // Dili İngilizce yap
        await tester.tap(find.text('İngilizce'));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);

        // Temayı Dark yap
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(container.read(themeModeProvider), ThemeMode.dark);

        final materialApp =
            tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.themeMode, ThemeMode.dark);

        // Ana ekrana dön -> İngilizce olmalı
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Start New Workflow'), findsOneWidget);
      },
    );
  });
}
