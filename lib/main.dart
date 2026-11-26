import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/l10n/app_strings.dart';
import 'features/saved/saved_workflows_controller.dart';
import 'features/saved/saved_workflows_screen.dart';
import 'features/settings/settings_controller.dart';
import 'features/wizard/flow_controller.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final defaultLang =
      deviceLocale.languageCode.toLowerCase() == 'tr' ? AppLang.tr : AppLang.en;

  WorkflowStorage storageService;
  SettingsStorage settingsService;
  var storageInitFailed = false;

  try {
    await Hive.initFlutter();
    final workflowsBox = await Hive.openBox<String>(StorageService.boxName);
    final settingsBox = await Hive.openBox<String>(SettingsService.boxName);
    storageService = StorageService(workflowsBox);
    settingsService = SettingsService(settingsBox);
  } catch (e, stack) {
    debugPrint('Hive başlatılamadı, bellek içi depolamaya geçiliyor: $e\n$stack');
    storageInitFailed = true;
    storageService = InMemoryStorageService();
    settingsService = InMemorySettingsService(initialLang: defaultLang);
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        settingsServiceProvider.overrideWithValue(settingsService),
        defaultAppLangProvider.overrideWithValue(defaultLang),
        storageInitFailedProvider.overrideWith((ref) => storageInitFailed),
      ],
      child: const FlowForgeApp(),
    ),
  );
}

/// FlowForge kök uygulama widget'ı.
class FlowForgeApp extends ConsumerWidget {
  const FlowForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lang = ref.watch(appLangProvider);

    return MaterialApp(
      title: AppStrings.lookup('app_name', lang),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      home: const SavedWorkflowsScreen(),
    );
  }
}
