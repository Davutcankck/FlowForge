import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/saved/saved_workflows_controller.dart';
import 'features/saved/saved_workflows_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WorkflowStorage storageService;
  try {
    await Hive.initFlutter();
    final workflowsBox = await Hive.openBox<String>(StorageService.boxName);
    storageService = StorageService(workflowsBox);
  } catch (e, stack) {
    debugPrint('Hive başlatılamadı, bellek içi depolamaya geçiliyor: $e\n$stack');
    storageService = InMemoryStorageService();
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const FlowForgeApp(),
    ),
  );
}

/// FlowForge kök uygulama widget'ı.
class FlowForgeApp extends StatelessWidget {
  const FlowForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowForge',
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
      themeMode: ThemeMode.system,
      home: const SavedWorkflowsScreen(),
    );
  }
}
