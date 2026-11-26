import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../core/l10n/app_strings.dart';

/// Uygulama ayarları (dil ve tema) modeli.
@immutable
class AppSettings {
  const AppSettings({
    required this.lang,
    required this.themeMode,
  });

  final AppLang lang;
  final ThemeMode themeMode;

  AppSettings copyWith({
    AppLang? lang,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      lang: lang ?? this.lang,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.lang == lang &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => Object.hash(lang, themeMode);
}

/// Ayarlar kalıcılık sözleşmesi.
abstract interface class SettingsStorage {
  AppSettings load({required AppLang defaultLang});
  Future<void> saveLang(AppLang lang);
  Future<void> saveThemeMode(ThemeMode mode);
}

/// Hive `settings` kutusu üzerinde dil ve tema kalıcılığı sağlayan servis.
class SettingsService implements SettingsStorage {
  SettingsService(this._box);

  static const String boxName = 'settings';
  static const String languageKey = 'language';
  static const String themeModeKey = 'themeMode';

  final Box<String> _box;

  @override
  AppSettings load({required AppLang defaultLang}) {
    final rawLang = _box.get(languageKey);
    final lang = switch (rawLang) {
      'tr' => AppLang.tr,
      'en' => AppLang.en,
      _ => defaultLang,
    };

    final rawTheme = _box.get(themeModeKey);
    final themeMode = switch (rawTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };

    return AppSettings(lang: lang, themeMode: themeMode);
  }

  @override
  Future<void> saveLang(AppLang lang) async {
    await _box.put(languageKey, lang.name);
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _box.put(themeModeKey, mode.name);
  }
}

/// Testler ve Hive başlatılamayan ortamlar için bellek içi ayarlar servisi.
class InMemorySettingsService implements SettingsStorage {
  InMemorySettingsService({
    AppLang? initialLang,
    ThemeMode initialThemeMode = ThemeMode.system,
  })  : _lang = initialLang,
        _themeMode = initialThemeMode;

  AppLang? _lang;
  ThemeMode _themeMode;

  @override
  AppSettings load({required AppLang defaultLang}) {
    return AppSettings(
      lang: _lang ?? defaultLang,
      themeMode: _themeMode,
    );
  }

  @override
  Future<void> saveLang(AppLang lang) async {
    _lang = lang;
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }
}
