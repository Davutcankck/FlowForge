import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/workflow_model.dart';
import '../preview/preview_screen.dart';
import '../wizard/flow_controller.dart';
import '../wizard/wizard_screen.dart';
import 'saved_workflows_controller.dart';

/// Ana ekran: "Yeni Workflow" butonu ve cihazda kayıtlı akışlar listesi (SDD 6.1, FR-09).
class SavedWorkflowsScreen extends ConsumerWidget {
  const SavedWorkflowsScreen({super.key});

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    WorkflowModel workflow,
  ) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _RenameSavedWorkflowDialog(initialName: workflow.name),
    );
    if (updated != null && updated.isNotEmpty) {
      await ref
          .read(savedWorkflowsProvider.notifier)
          .rename(workflow.id, updated);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkflowModel workflow,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Workflow Silinsin mi?'),
          content: Text(
            '"${workflow.name}" akışı cihazdan kalıcı olarak silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            FilledButton(
              key: const Key('confirm_delete_workflow_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(savedWorkflowsProvider.notifier).delete(workflow.id);
    }
  }

  void _startNew(BuildContext context, WidgetRef ref) {
    ref.read(flowControllerProvider.notifier).startNewWorkflow();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WizardScreen()),
    );
  }

  void _openSaved(BuildContext context, WidgetRef ref, WorkflowModel workflow) {
    ref.read(flowControllerProvider.notifier).loadSavedWorkflow(workflow);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadResult = ref.watch(savedWorkflowsProvider);
    final workflows = loadResult.workflows;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowForge'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loadResult.hasCorrupted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  key: const Key('corrupted_records_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE65100).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE65100),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${loadResult.corruptedIds.length} bozuk kayıt okunamadığı için atlandı.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFFE65100)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: workflows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_tree_rounded,
                            size: 68,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz kayıtlı akış yok',
                            key: const Key('saved_empty_state_title'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Birkaç kısa soruyu cevaplayarak çevrimdışı olarak n8n JSON ve draw.io diyagramı oluşturabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: workflows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final workflow = workflows[index];
                        return Card(
                          key: Key('saved_workflow_card_${workflow.id}'),
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              child: const Icon(Icons.account_tree_outlined),
                            ),
                            title: Text(
                              workflow.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${workflow.nodes.length} düğüm · ${_formatDateTime(workflow.updatedAt)}',
                            ),
                            onTap: () => _openSaved(context, ref, workflow),
                            trailing: PopupMenuButton<String>(
                              key: Key('saved_workflow_menu_${workflow.id}'),
                              onSelected: (action) {
                                if (action == 'rename') {
                                  _showRenameDialog(context, ref, workflow);
                                } else if (action == 'delete') {
                                  _confirmDelete(context, ref, workflow);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Yeniden Adlandır'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.delete_outline_rounded),
                                    title: Text('Sil'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton.icon(
                key: const Key('start_new_workflow_button'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Workflow Başlat'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => _startNew(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameSavedWorkflowDialog extends StatefulWidget {
  const _RenameSavedWorkflowDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameSavedWorkflowDialog> createState() =>
      _RenameSavedWorkflowDialogState();
}

class _RenameSavedWorkflowDialogState
    extends State<_RenameSavedWorkflowDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Workflow Adını Düzenle'),
      content: TextField(
        key: const Key('saved_rename_field'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Workflow adı',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const Key('confirm_saved_rename_button'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
