import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/l10n/app_strings.dart';

/// Tek satır (`//`) ve çok satırlı (`/* ... */`) yorumları temizler.
String _stripDartComments(String source) {
  final withoutBlock = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return withoutBlock.replaceAll(RegExp(r'//.*$', multiLine: true), '');
}

void main() {
  group('L10n (AppStrings ve Sabit Türkçe Metin Taraması)', () {
    test('tüm AppStrings anahtarları hem tr hem en için boş olmayan değer döner',
        () {
      expect(AppStrings.allKeys, isNotEmpty);
      for (final key in AppStrings.allKeys) {
        final tr = AppStrings.lookup(key, AppLang.tr);
        final en = AppStrings.lookup(key, AppLang.en);
        expect(tr.trim(), isNotEmpty, reason: 'TR boş: $key');
        expect(en.trim(), isNotEmpty, reason: 'EN boş: $key');
      }
    });

    test('AppStrings.format yer tutucuları doğru yerleştirir', () {
      expect(
        AppStrings.format('wizard.step', AppLang.tr, {'step': 3}),
        'Adım 3',
      );
      expect(
        AppStrings.format('wizard.step', AppLang.en, {'step': 3}),
        'Step 3',
      );
      expect(
        AppStrings.format('export.savedSnack', AppLang.en, {'name': 'Order'}),
        '"Order" saved to device.',
      );
    });

    test(
      'lib/features altında hiçbir arayüz dosyasında Türkçe karakter içeren sabit string literal kalmamıştır',
      () {
        final featuresDir = Directory('lib/features');
        expect(featuresDir.existsSync(), isTrue);

        final dartFiles = featuresDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList();
        expect(dartFiles, isNotEmpty);

        final turkishLiteralRegex = RegExp(
          r'''(['"])(?:\\.|(?!\1).)*[çğıöşüÇĞİÖŞÜ](?:\\.|(?!\1).)*\1''',
        );

        final violations = <String>[];
        for (final file in dartFiles) {
          final cleaned = _stripDartComments(file.readAsStringSync());
          final lines = cleaned.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final match = turkishLiteralRegex.firstMatch(lines[i]);
            if (match != null) {
              violations.add('${file.path}:${i + 1}: ${match.group(0)}');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Sabit Türkçe metin tespit edildi:\n${violations.join('\n')}',
        );
      },
    );
  });
}
