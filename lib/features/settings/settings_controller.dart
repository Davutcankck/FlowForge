import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../services/settings_service.dart';

/// Ayarlar kalıcılık servisi sağlayıcısı (üretimde `main.dart` üzerinden Hive
/// `SettingsService` ile override edilir).
final settingsServiceProvider = Provider<SettingsStorage>((ref) {
  return InMemorySettingsService(initialLang: AppLang.tr);
});

/// Cihaz dilinden türetilen varsayılan dil (üretimde `PlatformDispatcher` ile
/// override edilir; testlerde deterministik `AppLang.tr`).
final defaultAppLangProvider = Provider<AppLang>((ref) => AppLang.tr);

/// Hive başlatma hatası olduysa `true` olur; ana ekranda bilgilendirme banner'ı açılır.
final storageInitFailedProvider = StateProvider<bool>((ref) => false);

/// Dil ve tema ayarlarını yöneten Riverpod Notifier.
class SettingsController extends Notifier<AppSettings> {
  SettingsStorage get _storage => ref.read(settingsServiceProvider);

  @override
  AppSettings build() {
    final defaultLang = ref.watch(defaultAppLangProvider);
    return _storage.load(defaultLang: defaultLang);
  }

  Future<void> setLang(AppLang lang) async {
    state = state.copyWith(lang: lang);
    await _storage.saveLang(lang);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.saveThemeMode(mode);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// Aktif tema modu sağlayıcısı.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsControllerProvider).themeMode;
});
