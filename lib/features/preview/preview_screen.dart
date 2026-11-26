import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/workflow_node.dart';
import '../export/export_summary_screen.dart';
import '../wizard/flow_controller.dart';
import 'canvas_layout_geometry.dart';
import 'widgets/node_param_sheet.dart';
import 'workflow_canvas_painter.dart';

/// Yakınlaştırma/kaydırma ve düğüme dokunarak parametre düzenleme destekli
/// canlı workflow önizleme ekranı (SDD 6.1, FR-05, FR-11).
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _RenameWorkflowDialog(initialName: currentName),
    );

    if (updated != null && updated.isNotEmpty) {
      ref.read(flowControllerProvider.notifier).renameWorkflow(updated);
    }
  }

  void _openNodeParamSheet(
    BuildContext context,
    WidgetRef ref,
    WorkflowNode node,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NodeParamSheet(
        node: node,
        onSave: (params) {
          ref
              .read(flowControllerProvider.notifier)
              .updateNodeParams(node.id, params);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(laidOutWorkflowProvider);
    final issues = ref.watch(validationIssuesProvider);
    final warningNodeIds = issues
        .where((i) => i.code == 'V-04' && i.nodeId != null)
        .map((i) => i.nodeId!)
        .toSet();
    final geometry = CanvasLayoutGeometry.fromModel(model);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          model.name,
          key: const Key('preview_workflow_title'),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('preview_rename_button'),
            tooltip: 'Workflow adını düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context, ref, model.name),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              key: const Key('preview_export_summary_button'),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Özet'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExportSummaryScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: model.nodes.isEmpty
          ? _EmptyPreviewState(
              onReturnToWizard: () => Navigator.of(context).maybePop(),
            )
          : Column(
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Parametre düzenlemek için bir düğüme dokunun. Yakınlaştırmak için sıkıştırın.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    key: const Key('preview_interactive_viewer'),
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(160),
                    minScale: 0.4,
                    maxScale: 2.5,
                    child: GestureDetector(
                      key: const Key('preview_canvas_gesture'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final tapped = geometry.hitTest(details.localPosition);
                        if (tapped != null) {
                          _openNodeParamSheet(context, ref, tapped);
                        }
                      },
                      child: SizedBox(
                        width: geometry.canvasSize.width,
                        height: geometry.canvasSize.height,
                        child: CustomPaint(
                          key: const Key('preview_workflow_canvas'),
                          size: geometry.canvasSize,
                          painter: WorkflowCanvasPainter(
                            model: model,
                            geometry: geometry,
                            warningNodeIds: warningNodeIds,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RenameWorkflowDialog extends StatefulWidget {
  const _RenameWorkflowDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameWorkflowDialog> createState() => _RenameWorkflowDialogState();
}

class _RenameWorkflowDialogState extends State<_RenameWorkflowDialog> {
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
        key: const Key('rename_workflow_field'),
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
          key: const Key('confirm_rename_workflow_button'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _EmptyPreviewState extends StatelessWidget {
  const _EmptyPreviewState({required this.onReturnToWizard});

  final VoidCallback onReturnToWizard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz düğüm eklenmedi',
              key: const Key('preview_empty_state_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk soruyu cevapladığınızda akış diyagramınız burada canlı olarak görünecek.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onReturnToWizard,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Soru Ekranına Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
