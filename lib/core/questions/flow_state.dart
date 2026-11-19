import 'package:flutter/foundation.dart';
import '../models/workflow_model.dart';

/// Akış içindeki bir node ve çıkış indeksini temsil eden imleç.
@immutable
class BranchCursor {
  final String nodeId;
  final int outputIndex;

  const BranchCursor({
    required this.nodeId,
    required this.outputIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranchCursor &&
        other.nodeId == nodeId &&
        other.outputIndex == outputIndex;
  }

  @override
  int get hashCode => Object.hash(nodeId, outputIndex);

  @override
  String toString() => 'BranchCursor(nodeId: $nodeId, outputIndex: $outputIndex)';

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'outputIndex': outputIndex,
      };

  factory BranchCursor.fromJson(Map<String, dynamic> json) => BranchCursor(
        nodeId: json['nodeId'] as String,
        outputIndex: json['outputIndex'] as int,
      );
}

/// Akış motorunun tüm durumunu tutan değişmez (immutable) sınıf.
@immutable
class FlowState {
  final WorkflowModel model;
  final String? currentQuestionId;
  final BranchCursor? activeBranch;
  final List<BranchCursor> branchStack;
  final Map<String, Map<String, dynamic>> userParams;
  final List<FlowState> undoStack;

  FlowState({
    required this.model,
    this.currentQuestionId,
    this.activeBranch,
    List<BranchCursor>? branchStack,
    Map<String, Map<String, dynamic>>? userParams,
    List<FlowState>? undoStack,
  })  : branchStack = List.unmodifiable(branchStack ?? const <BranchCursor>[]),
        userParams = Map.unmodifiable(userParams?.map(
              (k, v) => MapEntry(k, Map<String, dynamic>.unmodifiable(v)),
            ) ??
            const <String, Map<String, dynamic>>{}),
        undoStack = List.unmodifiable(undoStack ?? const <FlowState>[]);

  /// model node parametrelerinin üzerine userParams birleştirilmiş yeni model döner (immutable).
  WorkflowModel get effectiveModel {
    if (userParams.isEmpty) return model;
    final updatedNodes = model.nodes.map((node) {
      final overrideParams = userParams[node.id];
      if (overrideParams == null || overrideParams.isEmpty) {
        return node;
      }
      return node.copyWith(
        parameters: {
          ...node.parameters,
          ...overrideParams,
        },
      );
    }).toList();
    return model.copyWith(nodes: updatedNodes);
  }

  FlowState copyWith({
    WorkflowModel? model,
    String? currentQuestionId,
    bool clearCurrentQuestionId = false,
    BranchCursor? activeBranch,
    bool clearActiveBranch = false,
    List<BranchCursor>? branchStack,
    Map<String, Map<String, dynamic>>? userParams,
    List<FlowState>? undoStack,
  }) {
    return FlowState(
      model: model ?? this.model,
      currentQuestionId: clearCurrentQuestionId
          ? null
          : (currentQuestionId ?? this.currentQuestionId),
      activeBranch:
          clearActiveBranch ? null : (activeBranch ?? this.activeBranch),
      branchStack: branchStack ?? this.branchStack,
      userParams: userParams ?? this.userParams,
      undoStack: undoStack ?? this.undoStack,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model.toJson(),
      'currentQuestionId': currentQuestionId,
      'activeBranch': activeBranch?.toJson(),
      'branchStack': branchStack.map((b) => b.toJson()).toList(),
      'userParams': userParams,
      // NOT: undoStack bilerek toJson'a dahil edilmez.
    };
  }

  factory FlowState.fromJson(Map<String, dynamic> json) {
    return FlowState(
      model: WorkflowModel.fromJson(json['model'] as Map<String, dynamic>),
      currentQuestionId: json['currentQuestionId'] as String?,
      activeBranch: json['activeBranch'] != null
          ? BranchCursor.fromJson(json['activeBranch'] as Map<String, dynamic>)
          : null,
      branchStack: (json['branchStack'] as List<dynamic>?)
              ?.map((b) => BranchCursor.fromJson(b as Map<String, dynamic>))
              .toList() ??
          const [],
      userParams: (json['userParams'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ) ??
          const {},
      undoStack: const [],
    );
  }
}
