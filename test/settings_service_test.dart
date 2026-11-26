import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:flowforge/core/l10n/app_strings.dart';
import 'package:flowforge/services/settings_service.dart';

void main() {
  group('SettingsService (Hive)', () {
    late Directory tempDir;
    late Box<String> box;
    late SettingsService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('flowforge_settings_test_');
      Hive.init(tempDir.path);
      box = await Hive.openBox<String>(SettingsService.boxName);
      service = SettingsService(box);
    });

    tearDown(() async {
      if (box.isOpen) {
        await box.close();
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('kayıtlı değer yoksa cihaz varsayılan dilini ve ThemeMode.system döner',
        () {
      final enDefault = service.load(defaultLang: AppLang.en);
      expect(enDefault.lang, AppLang.en);
      expect(enDefault.themeMode, ThemeMode.system);

      final trDefault = service.load(defaultLang: AppLang.tr);
      expect(trDefault.lang, AppLang.tr);
      expect(trDefault.themeMode, ThemeMode.system);
    });

    test('dil ve tema tercihi kutu kapatılıp yeniden açıldığında kalıcı olarak durur',
        () async {
      await service.saveLang(AppLang.en);
      await service.saveThemeMode(ThemeMode.dark);
      await box.close();

      box = await Hive.openBox<String>(SettingsService.boxName);
      service = SettingsService(box);

      final loaded = service.load(defaultLang: AppLang.tr);
      expect(loaded.lang, AppLang.en);
      expect(loaded.themeMode, ThemeMode.dark);
    });
  });
}
