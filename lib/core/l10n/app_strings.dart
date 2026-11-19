/// Desteklenen uygulama dilleri.
enum AppLang {
  tr,
  en,
}

/// Uygulama metinleri ve yerelleştirme yardımcı sınıfı.
abstract final class AppStrings {
  static const Map<String, Map<AppLang, String>> _strings = {
    // Soru Başlıkları
    'q_trigger': {
      AppLang.tr: 'Akışı ne tetikleyecek?',
      AppLang.en: 'What triggers the workflow?',
    },
    'q_action': {
      AppLang.tr: 'Tetikleme sonrası ne yapılsın?',
      AppLang.en: 'What should happen after trigger?',
    },
    'q_condition': {
      AppLang.tr: 'Bir koşul kontrolü eklensin mi?',
      AppLang.en: 'Add a condition check?',
    },
    'q_output': {
      AppLang.tr: 'Sonuç nereye gönderilsin?',
      AppLang.en: 'Where should the output be sent?',
    },
    'q_branch_true': {
      AppLang.tr: 'Koşul DOĞRU ise ne yapılsın?',
      AppLang.en: 'If condition is TRUE, what to do?',
    },
    'q_branch_false': {
      AppLang.tr: 'Koşul YANLIŞ ise ne yapılsın?',
      AppLang.en: 'If condition is FALSE, what to do?',
    },
    'q_branch_continue': {
      AppLang.tr: 'Bu dala başka bir adım eklensin mi?',
      AppLang.en: 'Add another step to this branch?',
    },

    // Tetikleyici Seçenekleri
    'trigger.webhook': {
      AppLang.tr: 'Webhook (HTTP İsteği)',
      AppLang.en: 'Webhook (HTTP Request)',
    },
    'trigger.schedule': {
      AppLang.tr: 'Zamanlayıcı (Cron)',
      AppLang.en: 'Schedule (Cron)',
    },
    'trigger.telegramTrigger': {
      AppLang.tr: 'Telegram Mesajı',
      AppLang.en: 'Telegram Message',
    },

    // Aksiyon Seçenekleri
    'action.httpRequest': {
      AppLang.tr: 'HTTP İsteği Gönder',
      AppLang.en: 'Send HTTP Request',
    },
    'action.gmail': {
      AppLang.tr: 'Gmail E-postası Gönder',
      AppLang.en: 'Send Gmail Email',
    },
    'action.googleSheets': {
      AppLang.tr: 'Google Sheets\'e Satır Ekle',
      AppLang.en: 'Append to Google Sheets',
    },
    'action.telegram': {
      AppLang.tr: 'Telegram Mesajı Gönder',
      AppLang.en: 'Send Telegram Message',
    },
    'action.none': {
      AppLang.tr: 'İşlem yapmadan geç',
      AppLang.en: 'Skip action',
    },

    // Koşul Seçenekleri
    'cond.none': {
      AppLang.tr: 'Koşul yok, doğrudan devam et',
      AppLang.en: 'No condition, continue',
    },
    'cond.if': {
      AppLang.tr: 'Koşul ekle (IF / Else)',
      AppLang.en: 'Add condition (IF / Else)',
    },

    // Çıktı Seçenekleri
    'out.googleSheets': {
      AppLang.tr: 'Google Sheets\'e Kaydet',
      AppLang.en: 'Save to Google Sheets',
    },
    'out.telegram': {
      AppLang.tr: 'Telegram ile Bildir',
      AppLang.en: 'Notify via Telegram',
    },
    'out.gmail': {
      AppLang.tr: 'E-posta ile Bildir',
      AppLang.en: 'Notify via Email',
    },

    // Dal Seçenekleri
    'branch.empty': {
      AppLang.tr: 'Bu dalda bir şey yapma (Boş bırak)',
      AppLang.en: 'Do nothing in this branch',
    },
    'branch.end': {
      AppLang.tr: 'Bu dalı tamamla',
      AppLang.en: 'Complete this branch',
    },
  };

  /// Belirtilen [key] ve [lang] için metni döndürür.
  ///
  /// Anahtar veya dil bulunamazsa, anahtar adını içeren bir [StateError] fırlatır.
  static String lookup(String key, AppLang lang) {
    final entry = _strings[key];
    if (entry == null || !entry.containsKey(lang)) {
      throw StateError('Çeviri anahtarı bulunamadı: "$key" ($lang)');
    }
    return entry[lang]!;
  }
}
