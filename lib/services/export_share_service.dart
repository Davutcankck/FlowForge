import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Workflow adını tüm dosya sistemleri için güvenli dosya adına dönüştürür.
///
/// - Türkçe karakterleri ASCII karşılığına çevirir (`ç→c`, `ğ→g`, `ı/İ→i`, `ö→o`, `ş→s`, `ü→u`).
/// - Boşluk ve güvensiz karakterleri (`/ \ : * ? " < > |`) `_` yapar.
/// - Sonuç boşsa `flowforge_workflow` varsayılanını kullanır.
String sanitizeFileName(String rawName, {required String extension}) {
  const trMap = <String, String>{
    'ç': 'c',
    'Ç': 'c',
    'ğ': 'g',
    'Ğ': 'g',
    'ı': 'i',
    'İ': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ş': 's',
    'Ş': 's',
    'ü': 'u',
    'Ü': 'u',
  };

  final buffer = StringBuffer();
  for (final rune in rawName.trim().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(trMap[ch] ?? ch);
  }

  var sanitized = buffer
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

  if (sanitized.isEmpty) {
    sanitized = 'flowforge_workflow';
  }

  final cleanExt = extension.startsWith('.') ? extension : '.$extension';
  return '$sanitized$cleanExt';
}

/// Dışa aktarılan dosyaları yazma, sistem paylaşımı ve panoya kopyalama servisi (FR-10).
class ExportShareService {
  const ExportShareService();

  /// Metin içeriğini geçici dizine dosya olarak yazar ve sistem paylaşım menüsünü açar.
  Future<void> shareTextAsFile({
    required String content,
    required String fileName,
    required String subject,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject,
      ),
    );
  }

  /// Verilen metni sistem panosuna kopyalar.
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
