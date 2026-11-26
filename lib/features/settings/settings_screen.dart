import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../wizard/flow_controller.dart';
import 'settings_controller.dart';

/// Dil (TR/EN) ve tema (Sistem/Açık/Koyu) ayarları ekranı (SDD 6.1, FR-12).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final lang = ref.watch(appLangProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.lookup('settings.title', lang)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.lookup('settings.languageTitle', lang),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppLang>(
              key: const Key('settings_language_selector'),
              segments: [
                ButtonSegment<AppLang>(
                  value: AppLang.tr,
                  label: Text(AppStrings.lookup('settings.languageTr', lang)),
                ),
                ButtonSegment<AppLang>(
                  value: AppLang.en,
                  label: Text(AppStrings.lookup('settings.languageEn', lang)),
                ),
              ],
              selected: {settings.lang},
              onSelectionChanged: (selection) {
                controller.setLang(selection.first);
              },
            ),
            const SizedBox(height: 28),
            Text(
              AppStrings.lookup('settings.themeTitle', lang),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              key: const Key('settings_theme_selector'),
              segments: [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text(AppStrings.lookup('settings.themeSystem', lang)),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined, size: 18),
                  label: Text(AppStrings.lookup('settings.themeLight', lang)),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text(AppStrings.lookup('settings.themeDark', lang)),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) {
                controller.setThemeMode(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
