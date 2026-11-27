import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/layout/hit_tester.dart';
import '../../core/models/workflow_node.dart';
import '../export/export_summary_screen.dart';
import '../wizard/flow_controller.dart';
import 'widgets/node_param_sheet.dart';
import 'workflow_canvas_painter.dart';

/// Yakınlaştırma/kaydırma, dikey (yukarıdan aşağıya) yerleşim, ilk açılışta
/// `fitToScreen`, `+ / -` zoom kontrolleri ve düğüme dokunarak parametre düzenleme
/// destekli canlı workflow önizleme ekranı (SDD 6.1, FR-05, FR-11).
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  static const double _minScale = 0.3;
  static const double _maxScale = 2.5;
  static const double _zoomStepFactor = 1.25;

  final TransformationController _transformationController =
      TransformationController();
  Size? _lastViewportSize;
  Size? _lastCanvasSize;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Tuvali gerçek viewport boyutuna sığdırıp ortalar.
  ///
  /// `scale = min(viewW / canvasW, viewH / canvasH).clamp(0.3, 1.0)`
  void _fitToScreen(Size viewportSize, Size canvasSize) {
    if (viewportSize.width <= 0 ||
        viewportSize.height <= 0 ||
        canvasSize.width <= 0 ||
        canvasSize.height <= 0) {
      return;
    }

    final scale = math
        .min(
          viewportSize.width / canvasSize.width,
          viewportSize.height / canvasSize.height,
        )
        .clamp(_minScale, 1.0);

    final dx = (viewportSize.width - canvasSize.width * scale) / 2.0;
    final dy = (viewportSize.height - canvasSize.height * scale) / 2.0;

    final matrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, scale, 1.0);

    _transformationController.value = matrix;
  }

  /// Mevcut viewport merkezi etrafında ölçeği [factor] çarpanıyla büyütür veya küçültür.
  void _zoomBy(double factor) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final targetScale =
        (currentScale * factor).clamp(_minScale, _maxScale);
    if ((targetScale - currentScale).abs() < 0.001) return;

    final viewport = _lastViewportSize ?? const Size(400, 600);
    final focal = Offset(viewport.width / 2.0, viewport.height / 2.0);
    final currentTranslation = currentMatrix.getTranslation();

    // Sahnedeki odak noktasını koruyarak yeni ötelemeyi hesapla
    final sceneX = (focal.dx - currentTranslation.x) / currentScale;
    final sceneY = (focal.dy - currentTranslation.y) / currentScale;
    final nextDx = focal.dx - sceneX * targetScale;
    final nextDy = focal.dy - sceneY * targetScale;

    final matrix = Matrix4.identity()
      ..translateByDouble(nextDx, nextDy, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1.0);

    _transformationController.value = matrix;
  }

  Future<void> _showRenameDialog(String currentName, AppLang lang) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _RenameWorkflowDialog(
        initialName: currentName,
        lang: lang,
      ),
    );

    if (updated != null && updated.isNotEmpty) {
      ref.read(flowControllerProvider.notifier).renameWorkflow(updated);
    }
  }

  void _openNodeParamSheet(WorkflowNode node, AppLang lang) {
    ref.read(previewHintDismissedProvider.notifier).state = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NodeParamSheet(
        node: node,
        lang: lang,
        onSave: (params) {
          ref
              .read(flowControllerProvider.notifier)
              .updateNodeParams(node.id, params);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(effectiveWorkflowProvider);
    final layout = ref.watch(previewLayoutResultProvider);
    final issues = ref.watch(validationIssuesProvider);
    final hintDismissed = ref.watch(previewHintDismissedProvider);
    final lang = ref.watch(appLangProvider);
    final warningNodeIds = issues
        .where((i) => i.code == 'V-04' && i.nodeId != null)
        .map((i) => i.nodeId!)
        .toSet();
    const hitTester = CanvasHitTester();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          model.name,
          key: const Key('preview_workflow_title'),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (model.nodes.isNotEmpty)
            IconButton(
              key: const Key('preview_fit_screen_button'),
              tooltip: AppStrings.lookup('preview.fitScreen', lang),
              icon: const Icon(Icons.fit_screen_outlined),
              onPressed: () {
                if (_lastViewportSize != null) {
                  _fitToScreen(_lastViewportSize!, layout.canvasSize);
                }
              },
            ),
          IconButton(
            key: const Key('preview_rename_button'),
            tooltip: AppStrings.lookup('preview.renameTooltip', lang),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(model.name, lang),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              key: const Key('preview_export_summary_button'),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(AppStrings.lookup('preview.summary', lang)),
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
              lang: lang,
              onReturnToWizard: () => Navigator.of(context).maybePop(),
            )
          : Column(
              children: [
                if (!hintDismissed)
                  Material(
                    key: const Key('preview_hint_banner'),
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.lookup('preview.hint', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            key: const Key('dismiss_preview_hint_button'),
                            tooltip: AppStrings.lookup(
                              'preview.dismissHint',
                              lang,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              ref
                                  .read(previewHintDismissedProvider.notifier)
                                  .state = true;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportSize = constraints.biggest;
                          if (_lastViewportSize != viewportSize ||
                              _lastCanvasSize != layout.canvasSize) {
                            _lastViewportSize = viewportSize;
                            _lastCanvasSize = layout.canvasSize;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _fitToScreen(viewportSize, layout.canvasSize);
                            });
                          }

                          return InteractiveViewer(
                            key: const Key('preview_interactive_viewer'),
                            transformationController: _transformationController,
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(200),
                            minScale: _minScale,
                            maxScale: _maxScale,
                            child: GestureDetector(
                              key: const Key('preview_canvas_gesture'),
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) {
                                final currentScale = _transformationController
                                    .value
                                    .getMaxScaleOnAxis();
                                final tapped = hitTester.hitTest(
                                  scenePoint: details.localPosition,
                                  nodes: model.nodes,
                                  layout: layout,
                                  scale: currentScale,
                                );
                                if (tapped != null) {
                                  _openNodeParamSheet(tapped, lang);
                                }
                              },
                              child: SizedBox(
                                width: layout.canvasSize.width,
                                height: layout.canvasSize.height,
                                child: CustomPaint(
                                  key: const Key('preview_workflow_canvas'),
                                  size: layout.canvasSize,
                                  painter: WorkflowCanvasPainter(
                                    model: model,
                                    layout: layout,
                                    warningNodeIds: warningNodeIds,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: ValueListenableBuilder<Matrix4>(
                          valueListenable: _transformationController,
                          builder: (context, matrix, _) {
                            final scale = matrix.getMaxScaleOnAxis();
                            final pct = (scale * 100).round();
                            return Material(
                              elevation: 2,
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      key: const Key('preview_zoom_out_button'),
                                      tooltip: AppStrings.lookup(
                                        'preview.zoomOut',
                                        lang,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.remove_rounded),
                                      onPressed: scale > _minScale + 0.01
                                          ? () =>
                                              _zoomBy(1.0 / _zoomStepFactor)
                                          : null,
                                    ),
                                    InkWell(
                                      key: const Key(
                                        'preview_zoom_percent_label',
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        if (_lastViewportSize != null) {
                                          _fitToScreen(
                                            _lastViewportSize!,
                                            layout.canvasSize,
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          '$pct%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('preview_zoom_in_button'),
                                      tooltip: AppStrings.lookup(
                                        'preview.zoomIn',
                                        lang,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add_rounded),
                                      onPressed: scale < _maxScale - 0.01
                                          ? () => _zoomBy(_zoomStepFactor)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RenameWorkflowDialog extends StatefulWidget {
  const _RenameWorkflowDialog({
    required this.initialName,
    required this.lang,
  });

  final String initialName;
  final AppLang lang;

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
    final lang = widget.lang;
    return AlertDialog(
      title: Text(AppStrings.lookup('workflow.renameTitle', lang)),
      content: TextField(
        key: const Key('rename_workflow_field'),
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
          key: const Key('confirm_rename_workflow_button'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(AppStrings.lookup('common.save', lang)),
        ),
      ],
    );
  }
}

class _EmptyPreviewState extends StatelessWidget {
  const _EmptyPreviewState({
    required this.lang,
    required this.onReturnToWizard,
  });

  final AppLang lang;
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
              AppStrings.lookup('preview.emptyTitle', lang),
              key: const Key('preview_empty_state_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.lookup('preview.emptySubtitle', lang),
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
              label: Text(AppStrings.lookup('preview.backToWizard', lang)),
            ),
          ],
        ),
      ),
    );
  }
}
