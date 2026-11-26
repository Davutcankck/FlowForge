import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../catalog/node_catalog.dart';
import '../catalog/node_category.dart';
import '../models/workflow_model.dart';
import 'node_name_deduplicator.dart';

/// Doğrulama bulgusunun ciddiyet seviyesi.
enum ValidationSeverity {
  /// Dışa aktarmayı engelleyen kritik hata (V-01, V-03).
  error,

  /// Kullanıcı onayı ile dışa aktarmaya izin veren uyarı (V-02, V-04).
  warning,

  /// Otomatik düzeltilen bilgilendirme (V-05).
  info,
}

/// Tek bir doğrulama bulgusunu temsil eder.
@immutable
class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.nodeId,
  });

  final String code;
  final ValidationSeverity severity;
  final String message;
  final String? nodeId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationIssue &&
        other.code == code &&
        other.severity == severity &&
        other.message == message &&
        other.nodeId == nodeId;
  }

  @override
  int get hashCode => Object.hash(code, severity, message, nodeId);

  @override
  String toString() =>
      'ValidationIssue(code: $code, severity: $severity, nodeId: $nodeId, message: $message)';
}

/// Doğrulama sonuç listesi üzerinde dışa aktarma karar yardımcıları.
extension ValidationIssuesX on List<ValidationIssue> {
  /// Hata seviyesinde en az bir bulgu varsa `true`.
  bool get hasErrors => any((i) => i.severity == ValidationSeverity.error);

  /// Uyarı seviyesinde en az bir bulgu varsa `true`.
  bool get hasWarnings => any((i) => i.severity == ValidationSeverity.warning);

  /// Hata yoksa dışa aktarmaya izin verilir.
  bool get canExport => !hasErrors;

  /// Hata yok ancak uyarı varsa kullanıcıdan "yine de aktar" onayı istenir.
  bool get requiresConfirmation => !hasErrors && hasWarnings;
}

/// Dışa aktarma öncesi akışı SDD 5.5 kurallarına (V-01..V-05) göre doğrular.
class Validator {
  const Validator();

  /// Modeli doğrular ve bulgu listesini döndürür.
  List<ValidationIssue> validate(WorkflowModel model) {
    final issues = <ValidationIssue>[];

    _checkTriggerExists(model, issues);
    _checkDisconnectedNodes(model, issues);
    _checkCycles(model, issues);
    _checkRequiredParameters(model, issues);
    _checkUniqueNames(model, issues);

    return List.unmodifiable(issues);
  }

  /// V-01: En az bir trigger olmalı (Hata).
  void _checkTriggerExists(WorkflowModel model, List<ValidationIssue> issues) {
    final hasTrigger = model.nodes.any((node) {
      final template = NodeCatalog.byKey(node.templateKey);
      return template?.category == NodeCategory.trigger;
    });

    if (!hasTrigger) {
      issues.add(
        const ValidationIssue(
          code: 'V-01',
          severity: ValidationSeverity.error,
          message: 'Akışta en az bir tetikleyici (trigger) düğümü olmalıdır.',
        ),
      );
    }
  }

  /// V-02: Bağlantısız node olmamalı (Uyarı).
  void _checkDisconnectedNodes(
    WorkflowModel model,
    List<ValidationIssue> issues,
  ) {
    if (model.nodes.length <= 1) return;

    final nodeIds = model.nodes.map((n) => n.id).toSet();
    final outgoing = <String, List<String>>{};
    final connected = <String>{};

    for (final edge in model.edges) {
      if (!nodeIds.contains(edge.fromId) || !nodeIds.contains(edge.toId)) {
        continue;
      }
      outgoing.putIfAbsent(edge.fromId, () => []).add(edge.toId);
      connected.add(edge.fromId);
      connected.add(edge.toId);
    }

    final triggerIds = model.nodes
        .where(
          (n) => NodeCatalog.byKey(n.templateKey)?.category == NodeCategory.trigger,
        )
        .map((n) => n.id)
        .toList();

    if (triggerIds.isNotEmpty) {
      final reachable = <String>{};
      final queue = Queue<String>()..addAll(triggerIds);
      reachable.addAll(triggerIds);

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        for (final next in outgoing[current] ?? const <String>[]) {
          if (reachable.add(next)) {
            queue.add(next);
          }
        }
      }

      for (final node in model.nodes) {
        if (!reachable.contains(node.id)) {
          issues.add(
            ValidationIssue(
              code: 'V-02',
              severity: ValidationSeverity.warning,
              nodeId: node.id,
              message:
                  '"${node.name}" düğümü tetikleyiciye bağlı değil (bağlantısız düğüm).',
            ),
          );
        }
      }
    } else {
      for (final node in model.nodes) {
        if (!connected.contains(node.id)) {
          issues.add(
            ValidationIssue(
              code: 'V-02',
              severity: ValidationSeverity.warning,
              nodeId: node.id,
              message: '"${node.name}" düğümünün hiçbir bağlantısı yok.',
            ),
          );
        }
      }
    }
  }

  /// V-03: Döngü olmamalı (Hata) — 3-renkli DFS.
  void _checkCycles(WorkflowModel model, List<ValidationIssue> issues) {
    final nodeIds = model.nodes.map((n) => n.id).toSet();
    final outgoing = <String, List<String>>{};

    for (final edge in model.edges) {
      if (!nodeIds.contains(edge.fromId) || !nodeIds.contains(edge.toId)) {
        continue;
      }
      outgoing.putIfAbsent(edge.fromId, () => []).add(edge.toId);
    }

    // 0: unvisited, 1: visiting, 2: visited
    final state = <String, int>{};
    var cycleDetected = false;
    String? cycleNodeId;

    void dfs(String id) {
      if (cycleDetected) return;
      state[id] = 1;
      for (final next in outgoing[id] ?? const <String>[]) {
        final nextState = state[next] ?? 0;
        if (nextState == 1) {
          cycleDetected = true;
          cycleNodeId = next;
          return;
        }
        if (nextState == 0) {
          dfs(next);
          if (cycleDetected) return;
        }
      }
      state[id] = 2;
    }

    for (final node in model.nodes) {
      if ((state[node.id] ?? 0) == 0) {
        dfs(node.id);
        if (cycleDetected) break;
      }
    }

    if (cycleDetected) {
      issues.add(
        ValidationIssue(
          code: 'V-03',
          severity: ValidationSeverity.error,
          nodeId: cycleNodeId,
          message: 'Akışta döngü (cycle) tespit edildi.',
        ),
      );
    }
  }

  /// V-04: Zorunlu parametreler dolu olmalı (Uyarı) — katalogdan okunur (NFR-05).
  void _checkRequiredParameters(
    WorkflowModel model,
    List<ValidationIssue> issues,
  ) {
    for (final node in model.nodes) {
      final requiredKeys =
          NodeCatalog.byKey(node.templateKey)?.requiredParameters ??
              const <String>[];
      if (requiredKeys.isEmpty) continue;

      for (final key in requiredKeys) {
        final value = node.parameters[key];
        final isMissing = value == null ||
            (value is String && value.trim().isEmpty);
        if (isMissing) {
          issues.add(
            ValidationIssue(
              code: 'V-04',
              severity: ValidationSeverity.warning,
              nodeId: node.id,
              message:
                  '"${node.name}" düğümünde zorunlu "$key" parametresi boş.',
            ),
          );
        }
      }
    }
  }

  /// V-05: Node adları benzersiz olmalı (Otomatik düzeltilir — info).
  void _checkUniqueNames(WorkflowModel model, List<ValidationIssue> issues) {
    final resolved = resolveUniqueNames(model);
    for (final node in model.nodes) {
      final uniqueName = resolved[node.id]!;
      if (uniqueName != node.name) {
        issues.add(
          ValidationIssue(
            code: 'V-05',
            severity: ValidationSeverity.info,
            nodeId: node.id,
            message:
                '"${node.name}" adı tekrarlandığı için dışa aktarmada "$uniqueName" olarak otomatik düzeltilecek.',
          ),
        );
      }
    }
  }
}
