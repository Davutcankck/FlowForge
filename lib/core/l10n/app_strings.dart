/// Desteklenen uygulama dilleri.
enum AppLang {
  tr,
  en,
}

/// Uygulama metinleri ve yerelleştirme yardımcı sınıfı (FR-12).
abstract final class AppStrings {
  static const Map<String, Map<AppLang, String>> _strings = {
    // Uygulama Adı (Tek kaynak)
    'app_name': {
      AppLang.tr: 'FlowForge',
      AppLang.en: 'FlowForge',
    },

    // Ortak Aksiyonlar
    'common.cancel': {
      AppLang.tr: 'İptal',
      AppLang.en: 'Cancel',
    },
    'common.save': {
      AppLang.tr: 'Kaydet',
      AppLang.en: 'Save',
    },
    'common.close': {
      AppLang.tr: 'Kapat',
      AppLang.en: 'Close',
    },
    'common.delete': {
      AppLang.tr: 'Sil',
      AppLang.en: 'Delete',
    },

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
    'action.set': {
      AppLang.tr: 'Veri Alanlarını Düzenle (Set)',
      AppLang.en: 'Edit Fields (Set)',
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
    'out.respondToWebhook': {
      AppLang.tr: 'Webhook\'a Yanıt Dön',
      AppLang.en: 'Respond to Webhook',
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

    // Ana Ekran & Kayıtlı Akışlar
    'saved.deleteTitle': {
      AppLang.tr: 'Workflow Silinsin mi?',
      AppLang.en: 'Delete Workflow?',
    },
    'saved.deleteBody': {
      AppLang.tr: '"{name}" akışı cihazdan kalıcı olarak silinecek.',
      AppLang.en: '"{name}" will be permanently deleted from this device.',
    },
    'saved.deleteCorruptedTitle': {
      AppLang.tr: 'Bozuk Kayıtlar Silinsin mi?',
      AppLang.en: 'Delete Corrupted Records?',
    },
    'saved.deleteCorruptedBody': {
      AppLang.tr:
          '{count} okunamayan veya desteklenmeyen sürümdeki kayıt kalıcı olarak silinecek.',
      AppLang.en:
          '{count} unreadable or unsupported record(s) will be permanently deleted.',
    },
    'saved.corruptedBanner': {
      AppLang.tr: '{count} bozuk kayıt okunamadığı için atlandı.',
      AppLang.en: '{count} corrupted record(s) skipped.',
    },
    'saved.cleanCorrupted': {
      AppLang.tr: 'Temizle',
      AppLang.en: 'Clean up',
    },
    'saved.emptyTitle': {
      AppLang.tr: 'Henüz kayıtlı akış yok',
      AppLang.en: 'No saved workflows yet',
    },
    'saved.emptySubtitle': {
      AppLang.tr:
          'Birkaç kısa soruyu cevaplayarak çevrimdışı olarak n8n JSON ve draw.io diyagramı oluşturabilirsiniz.',
      AppLang.en:
          'Answer a few quick questions to build n8n JSON and draw.io diagrams offline.',
    },
    'saved.nodeCount': {
      AppLang.tr: '{count} düğüm',
      AppLang.en: '{count} nodes',
    },
    'saved.rename': {
      AppLang.tr: 'Yeniden Adlandır',
      AppLang.en: 'Rename',
    },
    'saved.startNew': {
      AppLang.tr: 'Yeni Workflow Başlat',
      AppLang.en: 'Start New Workflow',
    },
    'workflow.renameTitle': {
      AppLang.tr: 'Workflow Adını Düzenle',
      AppLang.en: 'Rename Workflow',
    },
    'workflow.nameLabel': {
      AppLang.tr: 'Workflow adı',
      AppLang.en: 'Workflow name',
    },
    'storage.initFailedBanner': {
      AppLang.tr:
          'Yerel depolama başlatılamadı. Değişiklikler yalnızca bu oturumda geçici olarak tutulur.',
      AppLang.en:
          'Local storage could not be initialized. Changes will only persist for this session.',
    },

    // Soru Ekranı (Wizard)
    'wizard.branchTrue': {
      AppLang.tr: 'Koşul: DOĞRU dalı',
      AppLang.en: 'Condition: TRUE branch',
    },
    'wizard.branchFalse': {
      AppLang.tr: 'Koşul: YANLIŞ dalı',
      AppLang.en: 'Condition: FALSE branch',
    },
    'wizard.undo': {
      AppLang.tr: 'Geri al',
      AppLang.en: 'Undo',
    },
    'wizard.preview': {
      AppLang.tr: 'Önizleme',
      AppLang.en: 'Preview',
    },
    'wizard.previewCount': {
      AppLang.tr: 'Önizleme ({count})',
      AppLang.en: 'Preview ({count})',
    },
    'wizard.step': {
      AppLang.tr: 'Adım {step}',
      AppLang.en: 'Step {step}',
    },
    'wizard.completedTitle': {
      AppLang.tr: 'Akış Tasarımı Tamamlandı',
      AppLang.en: 'Workflow Design Complete',
    },
    'wizard.completedBody': {
      AppLang.tr:
          '{count} düğümden oluşan akışınız hazır. Önizlemede parametreleri düzenleyebilir veya doğrulama özetini inceleyebilirsiniz.',
      AppLang.en:
          'Your {count}-node workflow is ready. You can edit parameters in Preview or inspect the validation summary.',
    },
    'wizard.openPreview': {
      AppLang.tr: 'Canlı Önizlemeyi Aç',
      AppLang.en: 'Open Live Preview',
    },
    'wizard.openExport': {
      AppLang.tr: 'Doğrulama ve Dışa Aktarma Özeti',
      AppLang.en: 'Validation & Export Summary',
    },

    // Önizleme & Parametre Düzenleme
    'preview.fitScreen': {
      AppLang.tr: 'Ekrana sığdır',
      AppLang.en: 'Fit to screen',
    },
    'preview.zoomIn': {
      AppLang.tr: 'Yakınlaştır',
      AppLang.en: 'Zoom in',
    },
    'preview.zoomOut': {
      AppLang.tr: 'Uzaklaştır',
      AppLang.en: 'Zoom out',
    },
    'preview.renameTooltip': {
      AppLang.tr: 'Workflow adını düzenle',
      AppLang.en: 'Rename workflow',
    },
    'preview.summary': {
      AppLang.tr: 'Özet',
      AppLang.en: 'Summary',
    },
    'preview.hint': {
      AppLang.tr:
          'Parametre düzenlemek için bir düğüme dokunun. Yakınlaştırmak için sıkıştırın.',
      AppLang.en: 'Tap a node to edit parameters. Pinch to zoom.',
    },
    'preview.dismissHint': {
      AppLang.tr: 'İpucunu kapat',
      AppLang.en: 'Dismiss hint',
    },
    'preview.emptyTitle': {
      AppLang.tr: 'Henüz düğüm eklenmedi',
      AppLang.en: 'No nodes added yet',
    },
    'preview.emptySubtitle': {
      AppLang.tr:
          'İlk soruyu cevapladığınızda akış diyagramınız burada canlı olarak görünecek.',
      AppLang.en:
          'Your workflow diagram will appear here live after your first answer.',
    },
    'preview.backToWizard': {
      AppLang.tr: 'Soru Ekranına Dön',
      AppLang.en: 'Back to Questions',
    },
    'params.emptyInfo': {
      AppLang.tr:
          'Bu düğüm için önceden tanımlı parametre yok. İsterseniz aşağıdan özel anahtar/değer parametresi ekleyebilirsiniz.',
      AppLang.en:
          'No predefined parameters for this node. You can add custom key/value parameters below.',
    },
    'params.requiredHelper': {
      AppLang.tr: 'Zorunlu parametre',
      AppLang.en: 'Required parameter',
    },
    'params.addCustomTitle': {
      AppLang.tr: 'Özel Parametre Ekle',
      AppLang.en: 'Add Custom Parameter',
    },
    'params.keyLabel': {
      AppLang.tr: 'Anahtar',
      AppLang.en: 'Key',
    },
    'params.valueLabel': {
      AppLang.tr: 'Değer',
      AppLang.en: 'Value',
    },
    'params.addTooltip': {
      AppLang.tr: 'Parametre ekle',
      AppLang.en: 'Add parameter',
    },
    'params.saveButton': {
      AppLang.tr: 'Değişiklikleri Kaydet',
      AppLang.en: 'Save Changes',
    },

    // Dışa Aktarma
    'export.title': {
      AppLang.tr: 'Dışa Aktarma ve Kayıt',
      AppLang.en: 'Export & Save',
    },
    'export.warningsDialogTitle': {
      AppLang.tr: 'Uyarılar Mevcut',
      AppLang.en: 'Warnings Present',
    },
    'export.warningsDialogBody': {
      AppLang.tr:
          'Akışta uyarı seviyesinde bulgular var. Yine de dışa aktarmak istiyor musunuz?',
      AppLang.en: 'The workflow has warnings. Do you still want to export?',
    },
    'export.proceedAnyway': {
      AppLang.tr: 'Yine de aktar',
      AppLang.en: 'Export anyway',
    },
    'export.copiedSnack': {
      AppLang.tr: 'n8n JSON panoya kopyalandı.',
      AppLang.en: 'n8n JSON copied to clipboard.',
    },
    'export.fileErrorTitle': {
      AppLang.tr: 'Dosya Dışa Aktarılamadı',
      AppLang.en: 'File Export Failed',
    },
    'export.fileErrorBody': {
      AppLang.tr:
          'Dosya yazma veya paylaşım sırasında bir sorun oluştu ({error}). İsterseniz n8n JSON çıktısını doğrudan panoya kopyalayabilirsiniz.',
      AppLang.en:
          'Failed to write or share file ({error}). You can copy the n8n JSON directly to the clipboard instead.',
    },
    'export.fallbackCopyJson': {
      AppLang.tr: 'JSON\'u Panoya Kopyala',
      AppLang.en: 'Copy JSON to Clipboard',
    },
    'export.savedSnack': {
      AppLang.tr: '"{name}" cihaza kaydedildi.',
      AppLang.en: '"{name}" saved to device.',
    },
    'export.blockedBody': {
      AppLang.tr:
          'Kritik doğrulama hataları giderilmeden dışa aktarma çıktısı üretilmez.',
      AppLang.en: 'Fix critical validation errors before exporting.',
    },
    'export.shareN8n': {
      AppLang.tr: 'n8n JSON Paylaş',
      AppLang.en: 'Share n8n JSON',
    },
    'export.shareDrawio': {
      AppLang.tr: 'draw.io Paylaş',
      AppLang.en: 'Share draw.io',
    },
    'export.copyClipboard': {
      AppLang.tr: 'Panoya Kopyala',
      AppLang.en: 'Copy to Clipboard',
    },
    'export.bannerErrorTitle': {
      AppLang.tr: 'Dışa Aktarma Engellendi',
      AppLang.en: 'Export Blocked',
    },
    'export.bannerErrorBody': {
      AppLang.tr: 'Devam etmek için hata seviyesindeki bulguları düzeltin.',
      AppLang.en: 'Fix error-level issues to continue.',
    },
    'export.bannerWarningTitle': {
      AppLang.tr: 'Uyarılar Mevcut (Yine de Aktarılabilir)',
      AppLang.en: 'Warnings Found (Can Still Export)',
    },
    'export.bannerWarningBody': {
      AppLang.tr:
          'Eksik parametre veya bağlantısız düğüm uyarısı var; isterseniz yine de aktarabilirsiniz.',
      AppLang.en:
          'There are missing parameter or disconnected node warnings; you can still export if desired.',
    },
    'export.bannerCleanTitle': {
      AppLang.tr: 'Akış Dışa Aktarmaya Hazır',
      AppLang.en: 'Workflow Ready to Export',
    },
    'export.bannerCleanBody': {
      AppLang.tr: 'Tüm doğrulama kontrolleri sorunsuz geçti.',
      AppLang.en: 'All validation checks passed.',
    },

    // Ayarlar
    'settings.title': {
      AppLang.tr: 'Ayarlar',
      AppLang.en: 'Settings',
    },
    'settings.languageTitle': {
      AppLang.tr: 'Dil',
      AppLang.en: 'Language',
    },
    'settings.languageTr': {
      AppLang.tr: 'Türkçe',
      AppLang.en: 'Turkish',
    },
    'settings.languageEn': {
      AppLang.tr: 'İngilizce',
      AppLang.en: 'English',
    },
    'settings.themeTitle': {
      AppLang.tr: 'Tema',
      AppLang.en: 'Theme',
    },
    'settings.themeSystem': {
      AppLang.tr: 'Sistem',
      AppLang.en: 'System',
    },
    'settings.themeLight': {
      AppLang.tr: 'Açık',
      AppLang.en: 'Light',
    },
    'settings.themeDark': {
      AppLang.tr: 'Koyu',
      AppLang.en: 'Dark',
    },
  };

  /// Katalogda tanımlı tüm çeviri anahtarları.
  static Iterable<String> get allKeys => _strings.keys;

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

  /// Yer tutucu (`{name}`, `{count}` vb.) içeren çeviri metnini biçimlendirir.
  static String format(
    String key,
    AppLang lang,
    Map<String, Object> args,
  ) {
    var text = lookup(key, lang);
    for (final entry in args.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return text;
  }
}
