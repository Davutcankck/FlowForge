import 'package:flutter/foundation.dart';

/// Seçeneğin seçilmesi durumunda yapılacak motor eylemi.
enum OptionAction {
  /// Modele yeni bir node ekler.
  addNode,

  /// Node eklemeden doğrudan q_condition sorusuna atlar (action.none).
  skipToCondition,

  /// Aktif dalı sonlandırır; yığında bekleyen dal varsa ona geçer, yoksa akışı bitirir.
  endBranch,

  /// Node eklemeden sonraki soruya geçer (cond.none).
  goNext,
}

/// Soru seçeneğini temsil eden değişmez (immutable) sınıf.
@immutable
class Option {
  final String labelKey;
  final OptionAction action;
  final String? nextQuestionId;
  final String? addsNodeKey;
  final Map<String, dynamic>? paramOverrides;

  const Option({
    required this.labelKey,
    required this.action,
    this.nextQuestionId,
    this.addsNodeKey,
    this.paramOverrides,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Option &&
        other.labelKey == labelKey &&
        other.action == action &&
        other.nextQuestionId == nextQuestionId &&
        other.addsNodeKey == addsNodeKey;
  }

  @override
  int get hashCode =>
      Object.hash(labelKey, action, nextQuestionId, addsNodeKey);

  @override
  String toString() => 'Option(labelKey: $labelKey, action: $action)';
}

/// Sihirbazda kullanıcıya sunulan soruyu temsil eden değişmez sınıf.
@immutable
class Question {
  final String id;
  final String textKey;
  final List<Option> options;

  Question({
    required this.id,
    required this.textKey,
    required List<Option> options,
  }) : options = List.unmodifiable(options);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id && other.textKey == textKey;
  }

  @override
  int get hashCode => Object.hash(id, textKey);

  @override
  String toString() => 'Question(id: $id, textKey: $textKey)';
}
