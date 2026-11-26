import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/workflow_model.dart';
import '../../services/export_share_service.dart';
import '../../services/storage_service.dart';

/// Yerel depolama sağlayıcısı (üretimde `main.dart` üzerinden Hive `StorageService`
/// ile override edilir; testlerde varsayılan olarak bellek içi çalışır).
final storageServiceProvider = Provider<WorkflowStorage>((ref) {
  return InMemoryStorageService();
});

/// Dosya paylaşma ve panoya kopyalama servisi sağlayıcısı.
final exportShareServiceProvider = Provider<ExportShareService>((ref) {
  return const ExportShareService();
});

/// Kayıtlı akış listesi state yöneticisi (FR-09).
class SavedWorkflowsController extends Notifier<StorageLoadResult> {
  WorkflowStorage get _storage => ref.read(storageServiceProvider);

  @override
  StorageLoadResult build() {
    return _storage.loadAll();
  }

  /// Kayıtları yeniden yükler.
  void refresh() {
    state = _storage.loadAll();
  }

  /// Akışı kaydeder (aynı ID varsa günceller) ve listeyi yeniler.
  Future<void> save(WorkflowModel model) async {
    await _storage.save(model.copyWith(updatedAt: DateTime.now()));
    state = _storage.loadAll();
  }

  /// Akışı siler ve listeyi yeniler.
  Future<void> delete(String id) async {
    await _storage.delete(id);
    state = _storage.loadAll();
  }

  /// Kullanıcı onayı ile bozuk kayıtları siler ve listeyi yeniler.
  Future<void> deleteCorrupted(List<String> ids) async {
    for (final id in ids) {
      await _storage.delete(id);
    }
    state = _storage.loadAll();
  }

  /// Akışı yeniden adlandırır ve listeyi yeniler.
  Future<void> rename(String id, String newName) async {
    await _storage.rename(id, newName);
    state = _storage.loadAll();
  }
}

final savedWorkflowsProvider =
    NotifierProvider<SavedWorkflowsController, StorageLoadResult>(
  SavedWorkflowsController.new,
);
