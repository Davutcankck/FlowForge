import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/questions/flow_state.dart';
import '../../core/questions/question.dart';
import '../../core/questions/question_flow.dart';
import '../export/export_summary_screen.dart';
import '../preview/preview_screen.dart';
import 'flow_controller.dart';
import 'widgets/option_card.dart';

/// Karar ağacı tabanlı soru ekranı (SDD 6.1, 6.3, FR-02..FR-05).
class WizardScreen extends ConsumerWidget {
  const WizardScreen({super.key});

  static const _stepProgressByQuestion = <String, double>{
    'q_trigger': 0.15,
    'q_action': 0.35,
    'q_condition': 0.55,
    'q_output': 0.75,
    'q_branch_true': 0.70,
    'q_branch_false': 0.85,
    'q_branch_continue': 0.90,
  };

  IconData _iconForOption(Option option) {
    final key = option.labelKey;
    if (key.startsWith('trigger.')) return Icons.bolt_rounded;
    if (key == 'action.none') return Icons.skip_next_rounded;
    if (key == 'action.set') return Icons.tune_rounded;
    if (key.startsWith('action.')) return Icons.play_arrow_rounded;
    if (key == 'cond.if') return Icons.call_split_rounded;
    if (key == 'cond.none') return Icons.arrow_forward_rounded;
    if (key == 'out.respondToWebhook') return Icons.reply_rounded;
    if (key.startsWith('out.')) return Icons.send_rounded;
    if (key == 'branch.empty') return Icons.block_rounded;
    if (key == 'branch.end') return Icons.check_circle_outline_rounded;
    return Icons.circle_outlined;
  }

  bool _isSecondaryOption(Option option) {
    return option.action == OptionAction.endBranch ||
        option.action == OptionAction.skipToCondition ||
        option.labelKey == 'cond.none';
  }

  String? _activeBranchLabel(FlowState state, AppLang lang) {
    final qId = state.currentQuestionId;
    if (qId == 'q_branch_true') {
      return AppStrings.lookup('wizard.branchTrue', lang);
    }
    if (qId == 'q_branch_false') {
      return AppStrings.lookup('wizard.branchFalse', lang);
    }
    final branch = state.activeBranch;
    if (branch != null) {
      final parent = state.model.nodeById(branch.nodeId);
      if (parent?.templateKey == 'if') {
        return branch.outputIndex == 0
            ? AppStrings.lookup('wizard.branchTrue', lang)
            : AppStrings.lookup('wizard.branchFalse', lang);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(flowControllerProvider);
    final options = ref.watch(availableOptionsProvider);
    final lang = ref.watch(appLangProvider);
    final controller = ref.read(flowControllerProvider.notifier);

    final nodeCount = flowState.model.nodes.length;
    final questionId = flowState.currentQuestionId;
    final question = questionId != null ? QuestionFlow.byId(questionId) : null;
    final isCompleted = question == null;
    final progress = isCompleted
        ? 1.0
        : (_stepProgressByQuestion[questionId] ?? 0.5);
    final branchLabel = _activeBranchLabel(flowState, lang);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('wizard_undo_button'),
          tooltip: flowState.undoStack.isNotEmpty
              ? AppStrings.lookup('wizard.undo', lang)
              : AppStrings.lookup('common.close', lang),
          icon: Icon(
            flowState.undoStack.isNotEmpty
                ? Icons.undo_rounded
                : Icons.arrow_back_rounded,
          ),
          onPressed: () {
            if (flowState.undoStack.isNotEmpty) {
              controller.undo();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          flowState.model.name,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              key: const Key('wizard_preview_button'),
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: Text(
                nodeCount > 0
                    ? AppStrings.format(
                        'wizard.previewCount',
                        lang,
                        {'count': nodeCount},
                      )
                    : AppStrings.lookup('wizard.preview', lang),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PreviewScreen(),
                  ),
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: isCompleted
            ? _CompletedView(
                nodeCount: nodeCount,
                lang: lang,
                onOpenPreview: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PreviewScreen(),
                    ),
                  );
                },
                onOpenExportSummary: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExportSummaryScreen(),
                    ),
                  );
                },
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Üst yarı: adım bilgisi, dal rozeti ve soru başlığı
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      AppStrings.format(
                                        'wizard.step',
                                        lang,
                                        {'step': flowState.undoStack.length + 1},
                                      ),
                                    ),
                                  ),
                                  if (branchLabel != null)
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      avatar: const Icon(
                                        Icons.call_split_rounded,
                                        size: 16,
                                      ),
                                      label: Text(branchLabel),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.lookup(question.textKey, lang),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Alt yarı: tek elle erişilebilir seçim kartları (SDD 6.3)
                        Expanded(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < options.length; i++)
                                    OptionCard(
                                      key: Key('option_${options[i].labelKey}'),
                                      label: AppStrings.lookup(
                                        options[i].labelKey,
                                        lang,
                                      ),
                                      icon: _iconForOption(options[i]),
                                      isSecondary:
                                          _isSecondaryOption(options[i]),
                                      onTap: () => controller.answer(i),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({
    required this.nodeCount,
    required this.lang,
    required this.onOpenPreview,
    required this.onOpenExportSummary,
  });

  final int nodeCount;
  final AppLang lang;
  final VoidCallback onOpenPreview;
  final VoidCallback onOpenExportSummary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.lookup('wizard.completedTitle', lang),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.format('wizard.completedBody', lang, {'count': nodeCount}),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            key: const Key('completed_open_preview_button'),
            onPressed: onOpenPreview,
            icon: const Icon(Icons.account_tree_rounded),
            label: Text(AppStrings.lookup('wizard.openPreview', lang)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('completed_open_export_button'),
            onPressed: onOpenExportSummary,
            icon: const Icon(Icons.verified_outlined),
            label: Text(AppStrings.lookup('wizard.openExport', lang)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
