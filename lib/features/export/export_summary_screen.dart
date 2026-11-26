import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/drawio_exporter.dart';
import '../../core/export/n8n_exporter.dart';
import '../../core/export/validator.dart';
import '../wizard/flow_controller.dart';

/// Doğrulama sonuçlarını ve salt-okunur n8n JSON / draw.io XML özetini gösteren ekran.
///
/// Faz 4 sınırı: Doğrulama durumu (`hasErrors`, `requiresConfirmation`, temiz) ve
/// çıktı önizlemesi gösterilir. Kalıcı kayıt (`StorageService`), dosya paylaşımı
/// (`share_plus`) ve panoya kopyalama aksiyonları Faz 5'te bağlanacaktır.
class ExportSummaryScreen extends ConsumerWidget {
  const ExportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(laidOutWorkflowProvider);
    final issues = ref.watch(validationIssuesProvider);

    final canExport = issues.canExport;
    final n8nJson = canExport ? const N8nExporter().export(model) : null;
    final drawioXml = canExport ? const DrawioExporter().export(model) : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doğrulama ve Özet'),
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
                  constraints: const BoxConstraints(maxHeight: 170),
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
              const SizedBox(height: 8),
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
