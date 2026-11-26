import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flow_controller.dart';
import 'wizard_screen.dart';

/// Uygulama giriş ekranı (Faz 4: Yeni Workflow başlatma; Faz 5'te kayıtlı akışlar eklenecek).
class HomeEntryScreen extends ConsumerWidget {
  const HomeEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowForge'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.account_tree_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Otomasyon Akışını Adım Adım Tasarla',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Birkaç kısa soruyu cevaplayarak çevrimdışı olarak n8n JSON ve draw.io diyagramı üretin.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const Key('start_new_workflow_button'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Workflow Başlat'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () {
                  ref.read(flowControllerProvider.notifier).startNewWorkflow();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WizardScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
