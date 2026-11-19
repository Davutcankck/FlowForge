import 'dart:ui';
import '../catalog/node_catalog.dart';
import '../models/id_generator.dart';
import '../models/workflow_model.dart';
import 'flow_state.dart';
import 'question.dart';
import 'question_flow.dart';

/// Soru akışını yürüten, modeli güncelleyen ve geri alma (undo) işlemlerini yöneten motor.
class FlowEngine {
  final IdGenerator gen;

  FlowEngine({required this.gen});

  /// Akışı başlatır: boş model, ilk soru q_trigger.
  FlowState start() {
    return FlowState(
      model: WorkflowModel.empty(gen: gen),
      currentQuestionId: 'q_trigger',
      activeBranch: null,
      branchStack: const [],
      userParams: const {},
      undoStack: const [],
    );
  }

  /// Aktif soruya ait geçerli seçenekleri döner.
  /// Biten akışta boş liste döner.
  /// Aktif daldan köke doğru IF derinliği >= 3 ise `cond.if` seçeneğini gizler.
  List<Option> availableOptions(FlowState state) {
    final qId = state.currentQuestionId;
    if (qId == null) return const [];

    final question = QuestionFlow.byId(qId);
    if (question == null) return const [];

    final ifDepth = _calculateIfDepth(state);
    if (ifDepth >= 3) {
      return question.options.where((o) => o.labelKey != 'cond.if').toList();
    }
    return question.options;
  }

  /// Aktif daldan köke doğru yürüyerek atalardaki IF sayısını hesaplar.
  int _calculateIfDepth(FlowState state) {
    final currentCursor = state.activeBranch;
    if (currentCursor == null) return 0;

    var count = 0;
    var currentNodeId = currentCursor.nodeId;

    while (true) {
      final node = state.model.nodeById(currentNodeId);
      if (node == null) break;

      if (node.templateKey == 'if') {
        count++;
      }

      // Bu node'a gelen edge'i bul (toId == currentNodeId)
      final incomingEdge = state.model.edges
          .where((e) => e.toId == currentNodeId)
          .firstOrNull;
      if (incomingEdge == null) break;
      currentNodeId = incomingEdge.fromId;
    }

    return count;
  }

  /// Seçilen seçeneğe cevap verir.
  FlowState answer(FlowState state, int optionIndex) {
    if (state.currentQuestionId == null) {
      throw StateError('Akış tamamlanmışken cevap verilemez.');
    }

    final options = availableOptions(state);
    if (optionIndex < 0 || optionIndex >= options.length) {
      throw StateError(
          'Geçersiz seçenek indeksi: $optionIndex (toplam: ${options.length})');
    }

    final selected = options[optionIndex];

    // Undo için snapshot kaydı (en fazla 50)
    final snapshot = state.copyWith(undoStack: const []);
    final newUndoStack = [...state.undoStack, snapshot];
    final boundedUndoStack = newUndoStack.length > 50
        ? newUndoStack.sublist(newUndoStack.length - 50)
        : newUndoStack;

    switch (selected.action) {
      case OptionAction.addNode:
        final nodeKey = selected.addsNodeKey!;
        final template = NodeCatalog.byKey(nodeKey);
        if (template == null) {
          throw StateError('Katalogda bulunamayan şablon: $nodeKey');
        }

        final combinedParams = {
          ...template.defaultParameters,
          if (selected.paramOverrides != null) ...selected.paramOverrides!,
        };

        // Node ekle
        var updatedModel = state.model.addNode(
          templateKey: template.key,
          name: template.displayName,
          parameters: combinedParams,
          position: Offset.zero,
          gen: gen,
        );
        final newNode = updatedModel.nodes.last;

        // Varsa activeBranch'ten edge bağla
        if (state.activeBranch != null) {
          updatedModel = updatedModel.addEdge(
            fromId: state.activeBranch!.nodeId,
            toId: newNode.id,
            outputIndex: state.activeBranch!.outputIndex,
          );
        }

        // Dal yönetimi
        BranchCursor newActiveBranch;
        List<BranchCursor> newBranchStack = state.branchStack;

        if (template.key == 'if') {
          newActiveBranch = BranchCursor(nodeId: newNode.id, outputIndex: 0);
          newBranchStack = [
            ...state.branchStack,
            BranchCursor(nodeId: newNode.id, outputIndex: 1),
          ];
        } else {
          newActiveBranch = BranchCursor(nodeId: newNode.id, outputIndex: 0);
        }

        return state.copyWith(
          model: updatedModel,
          currentQuestionId: selected.nextQuestionId,
          activeBranch: newActiveBranch,
          branchStack: newBranchStack,
          undoStack: boundedUndoStack,
        );

      case OptionAction.skipToCondition:
        return state.copyWith(
          currentQuestionId: selected.nextQuestionId,
          undoStack: boundedUndoStack,
        );

      case OptionAction.goNext:
        return state.copyWith(
          currentQuestionId: selected.nextQuestionId,
          undoStack: boundedUndoStack,
        );

      case OptionAction.endBranch:
        if (state.branchStack.isEmpty) {
          // Akış bitti
          return state.copyWith(
            clearCurrentQuestionId: true,
            clearActiveBranch: true,
            branchStack: const [],
            undoStack: boundedUndoStack,
          );
        } else {
          // Yığından bekleyen dalı çek
          final poppedBranch = state.branchStack.last;
          final remainingStack =
              state.branchStack.sublist(0, state.branchStack.length - 1);
          return state.copyWith(
            currentQuestionId: 'q_branch_false',
            activeBranch: poppedBranch,
            branchStack: remainingStack,
            undoStack: boundedUndoStack,
          );
        }
    }
  }

  /// Son eylemi geri alır.
  FlowState undo(FlowState state) {
    if (state.undoStack.isEmpty) {
      throw StateError('Geri alınacak eylem bulunamadı (undoStack boş).');
    }

    final snapshot = state.undoStack.last;
    final remainingUndoStack =
        state.undoStack.sublist(0, state.undoStack.length - 1);

    // userParams budaması: Yalnızca snapshot.model'de kalan node id'leri korunur
    final remainingNodeIds = snapshot.model.nodes.map((n) => n.id).toSet();
    final cleanUserParams = Map<String, Map<String, dynamic>>.fromEntries(
      state.userParams.entries.where((e) => remainingNodeIds.contains(e.key)),
    );

    return snapshot.copyWith(
      undoStack: remainingUndoStack,
      userParams: cleanUserParams,
    );
  }

  /// Belirtilen node'un parametrelerini günceller (merge).
  /// Bilinmeyen nodeId için StateError fırlatır.
  FlowState updateParams(
      FlowState state, String nodeId, Map<String, dynamic> params) {
    if (state.model.nodeById(nodeId) == null) {
      throw StateError('Bilinmeyen node id: $nodeId');
    }

    final existing = state.userParams[nodeId] ?? const <String, dynamic>{};
    final merged = {
      ...existing,
      ...params,
    };

    final updatedMap = {
      ...state.userParams,
      nodeId: merged,
    };

    return state.copyWith(userParams: updatedMap);
  }
}
