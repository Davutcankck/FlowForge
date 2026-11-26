import 'dart:io';

/// NFR-06 kabul kriteri: motor (questions), layout ve exporter kodunda
/// en az %80 birim test kapsamı olmalı.
///
/// `flutter test --coverage` sonrası üretilen `coverage/lcov.info` dosyasını
/// okur ve her hedef katman ile toplam satır kapsamını doğrular.
void main() {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
      'HATA: coverage/lcov.info bulunamadı. '
      'Önce `flutter test --coverage` çalıştırın.',
    );
    exitCode = 1;
    return;
  }

  const targetDirs = <String>[
    'lib/core/questions/',
    'lib/core/layout/',
    'lib/core/export/',
    'lib/services/',
  ];

  final linesByDir = <String, int>{for (final d in targetDirs) d: 0};
  final hitsByDir = <String, int>{for (final d in targetDirs) d: 0};

  final content = lcov.readAsStringSync();
  final files = content.split('SF:');

  for (final block in files) {
    if (block.isEmpty) continue;
    final lines = block.split('\n');
    final normalizedPath = lines.first.trim().replaceAll('\\', '/');

    String? matchedDir;
    for (final dir in targetDirs) {
      if (normalizedPath.contains(dir)) {
        matchedDir = dir;
        break;
      }
    }
    if (matchedDir == null) continue;

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

    linesByDir[matchedDir] = (linesByDir[matchedDir] ?? 0) + total;
    hitsByDir[matchedDir] = (hitsByDir[matchedDir] ?? 0) + hit;
  }

  var grandTotal = 0;
  var grandHit = 0;
  var hasFailure = false;

  for (final dir in targetDirs) {
    final total = linesByDir[dir] ?? 0;
    final hit = hitsByDir[dir] ?? 0;
    grandTotal += total;
    grandHit += hit;

    if (total == 0) {
      stderr.writeln('HATA: $dir altında kapsam verisi bulunamadı.');
      hasFailure = true;
      continue;
    }

    final pct = hit / total * 100;
    stdout.writeln('$dir kapsamı: $hit / $total = ${pct.toStringAsFixed(1)}%');
    if (pct < 80) {
      stderr.writeln('HATA: $dir kapsamı %80 altındadır.');
      hasFailure = true;
    }
  }

  if (grandTotal > 0) {
    final totalPct = grandHit / grandTotal * 100;
    stdout.writeln(
      'Toplam (core + services): '
      '$grandHit / $grandTotal = ${totalPct.toStringAsFixed(1)}%',
    );
  }

  if (hasFailure) {
    exitCode = 1;
  } else {
    stdout.writeln('OK: Tüm hedef katmanlar %80 veya üzeri kapsamda.');
  }
}
