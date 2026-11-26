import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/workflow_model.dart';
import '../preview/preview_screen.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_screen.dart';
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
    AppLang lang,
  ) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _RenameSavedWorkflowDialog(
        initialName: workflow.name,
        lang: lang,
      ),
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
    AppLang lang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppStrings.lookup('saved.deleteTitle', lang)),
          content: Text(
            AppStrings.format('saved.deleteBody', lang, {'name': workflow.name}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppStrings.lookup('common.cancel', lang)),
            ),
            FilledButton(
              key: const Key('confirm_delete_workflow_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppStrings.lookup('common.delete', lang)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(savedWorkflowsProvider.notifier).delete(workflow.id);
    }
  }

  Future<void> _confirmDeleteCorrupted(
    BuildContext context,
    WidgetRef ref,
    List<String> corruptedIds,
    AppLang lang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppStrings.lookup('saved.deleteCorruptedTitle', lang)),
          content: Text(
            AppStrings.format(
              'saved.deleteCorruptedBody',
              lang,
              {'count': corruptedIds.length},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppStrings.lookup('common.cancel', lang)),
            ),
            FilledButton(
              key: const Key('confirm_delete_corrupted_button'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppStrings.lookup('common.delete', lang)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(savedWorkflowsProvider.notifier)
          .deleteCorrupted(corruptedIds);
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
    final storageInitFailed = ref.watch(storageInitFailedProvider);
    final lang = ref.watch(appLangProvider);
    final workflows = loadResult.workflows;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.lookup('app_name', lang)),
        actions: [
          IconButton(
            key: const Key('open_settings_button'),
            tooltip: AppStrings.lookup('settings.title', lang),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (storageInitFailed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  key: const Key('storage_init_failed_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFB71C1C).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storage_outlined,
                        color: Color(0xFFB71C1C),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.lookup('storage.initFailedBanner', lang),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFFB71C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          AppStrings.format(
                            'saved.corruptedBanner',
                            lang,
                            {'count': loadResult.corruptedIds.length},
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFFE65100)),
                        ),
                      ),
                      TextButton(
                        key: const Key('delete_corrupted_records_button'),
                        onPressed: () => _confirmDeleteCorrupted(
                          context,
                          ref,
                          loadResult.corruptedIds,
                          lang,
                        ),
                        child: Text(
                          AppStrings.lookup('saved.cleanCorrupted', lang),
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
                            AppStrings.lookup('saved.emptyTitle', lang),
                            key: const Key('saved_empty_state_title'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.lookup('saved.emptySubtitle', lang),
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
                        final nodeCountText = AppStrings.format(
                          'saved.nodeCount',
                          lang,
                          {'count': workflow.nodes.length},
                        );
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
                              '$nodeCountText · ${_formatDateTime(workflow.updatedAt)}',
                            ),
                            onTap: () => _openSaved(context, ref, workflow),
                            trailing: PopupMenuButton<String>(
                              key: Key('saved_workflow_menu_${workflow.id}'),
                              onSelected: (action) {
                                if (action == 'rename') {
                                  _showRenameDialog(
                                    context,
                                    ref,
                                    workflow,
                                    lang,
                                  );
                                } else if (action == 'delete') {
                                  _confirmDelete(context, ref, workflow, lang);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.edit_outlined),
                                    title: Text(
                                      AppStrings.lookup('saved.rename', lang),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    title: Text(
                                      AppStrings.lookup('common.delete', lang),
                                    ),
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
                label: Text(AppStrings.lookup('saved.startNew', lang)),
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
  const _RenameSavedWorkflowDialog({
    required this.initialName,
    required this.lang,
  });

  final String initialName;
  final AppLang lang;

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
    final lang = widget.lang;
    return AlertDialog(
      title: Text(AppStrings.lookup('workflow.renameTitle', lang)),
      content: TextField(
        key: const Key('saved_rename_field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: AppStrings.lookup('workflow.nameLabel', lang),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.lookup('common.cancel', lang)),
        ),
        FilledButton(
          key: const Key('confirm_saved_rename_button'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(AppStrings.lookup('common.save', lang)),
        ),
      ],
    );
  }
}
