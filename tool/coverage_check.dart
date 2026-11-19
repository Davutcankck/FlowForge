import 'dart:io';

/// Faz 2 kabul kriteri: lib/core/questions kapsamı %80 üzerinde olmalı.
/// `flutter test --coverage` sonrası üretilen coverage/lcov.info dosyasını
/// okur ve core/questions altındaki dosyaların satır kapsamını hesaplar.
void main() {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln('HATA: coverage/lcov.info bulunamadı. '
        'Önce `flutter test --coverage` çalıştırın.');
    exitCode = 1;
    return;
  }

  final content = lcov.readAsStringSync();
  final files = content.split('SF:');
  var questionsLines = 0;
  var questionsHit = 0;

  for (final block in files) {
    if (block.isEmpty) continue;
    final lines = block.split('\n');
    final rawPath = lines.first.trim();
    final normalizedPath = rawPath.replaceAll('\\', '/');

    if (!normalizedPath.contains('lib/core/questions/')) continue;

    var hit = 0;
    var total = 0;
    for (final line in lines.skip(1)) {
      if (line.startsWith('DA:')) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          total++;
          if ((int.tryParse(parts[1].trim()) ?? 0) > 0) hit++;
        }
      }
    }

    questionsLines += total;
    questionsHit += hit;
  }

  if (questionsLines == 0) {
    stderr.writeln('HATA: lib/core/questions/ altında dosya bulunamadı.');
    exitCode = 1;
    return;
  }

  final pct = (questionsHit / questionsLines * 100);
  stdout.writeln(
      'core/questions kapsamı: $questionsHit / $questionsLines = ${pct.toStringAsFixed(1)}%');

  if (pct < 80) {
    stderr.writeln('HATA: Kapsam %80 altındır.');
    exitCode = 1;
  } else {
    stdout.writeln('OK: Kapsam %80 veya üzeri.');
  }
}
