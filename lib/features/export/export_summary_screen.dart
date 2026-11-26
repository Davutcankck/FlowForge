import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/drawio_exporter.dart';
import '../../core/export/n8n_exporter.dart';
import '../../core/export/validator.dart';
import '../../core/models/workflow_model.dart';
import '../../services/export_share_service.dart';
import '../saved/saved_workflows_controller.dart';
import '../wizard/flow_controller.dart';

/// Doğrulama sonuçlarını, salt-okunur çıktı önizlemesini ve gerçek kaydetme,
/// dosya paylaşma (.json / .drawio) ve panoya kopyalama aksiyonlarını sunan ekran (FR-08..FR-10).
class ExportSummaryScreen extends ConsumerWidget {
  const ExportSummaryScreen({super.key});

  Future<bool> _confirmIfWarnings(
    BuildContext context,
    List<ValidationIssue> issues,
  ) async {
    if (!issues.requiresConfirmation) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Uyarılar Mevcut'),
          content: const Text(
            'Akışta uyarı seviyesinde bulgular var. Yine de dışa aktarmak istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            FilledButton(
              key: const Key('confirm_export_with_warnings_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yine de aktar'),
            ),
          ],
        );
      },
    );

    return proceed == true;
  }

  Future<void> _copyJson(
    BuildContext context,
    WidgetRef ref,
    String n8nJson,
    List<ValidationIssue> issues, {
    bool skipWarningCheck = false,
  }) async {
    if (!skipWarningCheck) {
      final ok = await _confirmIfWarnings(context, issues);
      if (!ok || !context.mounted) return;
    }

    await ref.read(exportShareServiceProvider).copyToClipboard(n8nJson);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('n8n JSON panoya kopyalandı.')),
    );
  }

  Future<void> _shareFile(
    BuildContext context,
    WidgetRef ref, {
    required WorkflowModel model,
    required String content,
    required String n8nJsonFallback,
    required String extension,
    required String subject,
    required List<ValidationIssue> issues,
  }) async {
    final ok = await _confirmIfWarnings(context, issues);
    if (!ok || !context.mounted) return;

    final fileName = sanitizeFileName(model.name, extension: extension);
    try {
      await ref.read(exportShareServiceProvider).shareTextAsFile(
            content: content,
            fileName: fileName,
            subject: subject,
          );
    } catch (e) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            key: const Key('file_write_error_dialog'),
            title: const Text('Dosya Dışa Aktarılamadı'),
            content: Text(
              'Dosya yazma veya paylaşım sırasında bir sorun oluştu ($e). '
              'İsterseniz n8n JSON çıktısını doğrudan panoya kopyalayabilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Kapat'),
              ),
              FilledButton.icon(
                key: const Key('fallback_copy_json_button'),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('JSON\'u Panoya Kopyala'),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _copyJson(
                    context,
                    ref,
                    n8nJsonFallback,
                    issues,
                    skipWarningCheck: true,
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _saveWorkflow(
    BuildContext context,
    WidgetRef ref,
    WorkflowModel model,
  ) async {
    await ref.read(savedWorkflowsProvider.notifier).save(model);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${model.name}" cihaza kaydedildi.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(effectiveWorkflowProvider);
    final layout = ref.watch(layoutResultProvider);
    final issues = ref.watch(validationIssuesProvider);

    final canExport = issues.canExport;
    final n8nJson =
        canExport ? const N8nExporter().export(model, layout: layout) : null;
    final drawioXml =
        canExport ? const DrawioExporter().export(model, layout: layout) : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dışa Aktarma ve Kayıt'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _ValidationStatusBanner(issues: issues),
              ),
              if (issues.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shrinkWrap: true,
                    itemCount: issues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return _IssueTile(issue: issues[index]);
                    },
                  ),
                ),
              const SizedBox(height: 6),
              if (canExport) ...[
                const TabBar(
                  tabs: [
                    Tab(text: 'n8n JSON'),
                    Tab(text: 'draw.io XML'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CodePreviewPane(
                        key: const Key('export_n8n_preview'),
                        content: n8nJson!,
                      ),
                      _CodePreviewPane(
                        key: const Key('export_drawio_preview'),
                        content: drawioXml!,
                      ),
                    ],
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kritik doğrulama hataları giderilmeden dışa aktarma çıktısı üretilmez.',
                        key: const Key('export_blocked_message'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('export_save_button'),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Kaydet'),
                  onPressed: model.nodes.isEmpty
                      ? null
                      : () => _saveWorkflow(context, ref, model),
                ),
                FilledButton.tonalIcon(
                  key: const Key('export_share_n8n_button'),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('n8n JSON Paylaş'),
                  onPressed: canExport
                      ? () => _shareFile(
                            context,
                            ref,
                            model: model,
                            content: n8nJson!,
                            n8nJsonFallback: n8nJson,
                            extension: '.json',
                            subject: '${model.name} (n8n JSON)',
                            issues: issues,
                          )
                      : null,
                ),
                FilledButton.tonalIcon(
                  key: const Key('export_share_drawio_button'),
                  icon: const Icon(Icons.schema_outlined, size: 18),
                  label: const Text('draw.io Paylaş'),
                  onPressed: canExport
                      ? () => _shareFile(
                            context,
                            ref,
                            model: model,
                            content: drawioXml!,
                            n8nJsonFallback: n8nJson!,
                            extension: '.drawio',
                            subject: '${model.name} (draw.io)',
                            issues: issues,
                          )
                      : null,
                ),
                OutlinedButton.icon(
                  key: const Key('export_copy_json_button'),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Panoya Kopyala'),
                  onPressed: canExport
                      ? () => _copyJson(context, ref, n8nJson!, issues)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidationStatusBanner extends StatelessWidget {
  const _ValidationStatusBanner({required this.issues});

  final List<ValidationIssue> issues;

  @override
  Widget build(BuildContext context) {
    final (Key key, Color bg, Color fg, IconData icon, String title, String subtitle) =
        issues.hasErrors
            ? (
                const Key('validation_banner_error'),
                const Color(0xFFFFEBEE),
                const Color(0xFFB71C1C),
                Icons.error_outline_rounded,
                'Dışa Aktarma Engellendi',
                'Devam etmek için hata seviyesindeki bulguları düzeltin.',
              )
            : issues.requiresConfirmation
                ? (
                    const Key('validation_banner_warning'),
                    const Color(0xFFFFF8E1),
                    const Color(0xFFE65100),
                    Icons.warning_amber_rounded,
                    'Uyarılar Mevcut (Yine de Aktarılabilir)',
                    'Eksik parametre veya bağlantısız düğüm uyarısı var; isterseniz yine de aktarabilirsiniz.',
                  )
                : (
                    const Key('validation_banner_clean'),
                    const Color(0xFFE8F5E9),
                    const Color(0xFF1B5E20),
                    Icons.check_circle_outline_rounded,
                    'Akış Dışa Aktarmaya Hazır',
                    'Tüm doğrulama kontrolleri sorunsuz geçti.',
                  );

    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final ValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (issue.severity) {
      ValidationSeverity.error => (
          Icons.cancel_outlined,
          const Color(0xFFC62828),
        ),
      ValidationSeverity.warning => (
          Icons.warning_amber_rounded,
          const Color(0xFFEF6C00),
        ),
      ValidationSeverity.info => (
          Icons.info_outline_rounded,
          const Color(0xFF1565C0),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            issue.code,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodePreviewPane extends StatelessWidget {
  const _CodePreviewPane({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          content,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
