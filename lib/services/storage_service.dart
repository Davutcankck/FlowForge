import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../core/models/workflow_model.dart';

/// [WorkflowStorage.loadAll] dönüş modeli (SDD 8 — bozuk kayıt koruması).
@immutable
class StorageLoadResult {
  const StorageLoadResult({
    required this.workflows,
    required this.corruptedIds,
  });

  final List<WorkflowModel> workflows;
  final List<String> corruptedIds;

  bool get hasCorrupted => corruptedIds.isNotEmpty;
}

/// Yerel akış depolama sözleşmesi (SDD 5.6).
abstract interface class WorkflowStorage {
  Future<void> save(WorkflowModel model);
  StorageLoadResult loadAll();
  Future<void> delete(String id);
  Future<WorkflowModel?> rename(String id, String newName);
}

/// Hive `workflows` kutusu üzerinden çevrimdışı kalıcı kayıt servisi (SDD 5.6).
///
/// - Kutu adı: `workflows` (`Box<String>`)
/// - Anahtar: `workflow.id`
/// - Değer: `schemaVersion` alanı içeren JSON metni
class StorageService implements WorkflowStorage {
  StorageService(this._box);

  static const String boxName = 'workflows';

  final Box<String> _box;

  @override
  Future<void> save(WorkflowModel model) async {
    final encoded = jsonEncode(model.toJson());
    await _box.put(model.id, encoded);
  }

  @override
  StorageLoadResult loadAll() {
    final workflows = <WorkflowModel>[];
    final corruptedIds = <String>[];

    for (final rawKey in _box.keys) {
      final key = rawKey.toString();
      final rawValue = _box.get(rawKey);
      if (rawValue == null || rawValue.trim().isEmpty) {
        corruptedIds.add(key);
        continue;
      }

      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is! Map<String, dynamic>) {
          corruptedIds.add(key);
          continue;
        }
        workflows.add(WorkflowModel.fromJson(decoded));
      } catch (_) {
        corruptedIds.add(key);
      }
    }

    workflows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return StorageLoadResult(
      workflows: List.unmodifiable(workflows),
      corruptedIds: List.unmodifiable(corruptedIds),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<WorkflowModel?> rename(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return null;

    final rawValue = _box.get(id);
    if (rawValue == null) return null;

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) return null;
      final existing = WorkflowModel.fromJson(decoded);
      final updated = existing.copyWith(
        name: trimmed,
        updatedAt: DateTime.now(),
      );
      await save(updated);
      return updated;
    } catch (_) {
      return null;
    }
  }
}

/// Testler veya Hive kutusu başlatılmamış ortamlar için bellek içi yedek depolama.
class InMemoryStorageService implements WorkflowStorage {
  InMemoryStorageService({Map<String, String>? initialRawEntries})
      : _entries = Map<String, String>.from(initialRawEntries ?? const {});

  final Map<String, String> _entries;

  @override
  Future<void> save(WorkflowModel model) async {
    _entries[model.id] = jsonEncode(model.toJson());
  }

  @override
  StorageLoadResult loadAll() {
    final workflows = <WorkflowModel>[];
    final corruptedIds = <String>[];

    for (final entry in _entries.entries) {
      try {
        final decoded = jsonDecode(entry.value);
        if (decoded is! Map<String, dynamic>) {
          corruptedIds.add(entry.key);
          continue;
        }
        workflows.add(WorkflowModel.fromJson(decoded));
      } catch (_) {
        corruptedIds.add(entry.key);
      }
    }

    workflows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return StorageLoadResult(
      workflows: List.unmodifiable(workflows),
      corruptedIds: List.unmodifiable(corruptedIds),
    );
  }

  @override
  Future<void> delete(String id) async {
    _entries.remove(id);
  }

  @override
  Future<WorkflowModel?> rename(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return null;

    final raw = _entries[id];
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final existing = WorkflowModel.fromJson(decoded);
      final updated = existing.copyWith(
        name: trimmed,
        updatedAt: DateTime.now(),
      );
      await save(updated);
      return updated;
    } catch (_) {
      return null;
    }
  }
}
