import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/validator.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/layout/auto_layout.dart';
import '../../core/models/id_generator.dart';
import '../../core/models/workflow_model.dart';
import '../../core/questions/flow_engine.dart';
import '../../core/questions/flow_state.dart';
import '../../core/questions/question.dart';
import '../settings/settings_controller.dart';

/// Üretimde UUID v4, testlerde deterministik override edilebilen ID üreticisi.
final idGeneratorProvider = Provider<IdGenerator>((ref) {
  return UuidIdGenerator();
});

/// Soru akışı motoru sağlayıcısı.
final flowEngineProvider = Provider<FlowEngine>((ref) {
  return FlowEngine(gen: ref.watch(idGeneratorProvider));
});

/// Uygulama dili (SettingsController üzerinden kalıcı yönetilir).
final appLangProvider = Provider<AppLang>((ref) {
  return ref.watch(settingsControllerProvider).lang;
});

/// Önizleme ipucu bandının bu oturumda kapatılıp kapatılmadığı.
final previewHintDismissedProvider = StateProvider<bool>((ref) => false);

/// Tek yönlü akış state yöneticisi (SDD Bölüm 2 & 5.1).
class FlowController extends Notifier<FlowState> {
  FlowEngine get _engine => ref.read(flowEngineProvider);

  @override
  FlowState build() {
    return _engine.start();
  }

  /// Yeni boş workflow başlatır (FR-01).
  void startNewWorkflow() {
    state = _engine.start();
  }

  /// Cihazda kayıtlı bir workflow'u aynı ID ile düzenlenmek üzere yükler (FR-09).
  void loadSavedWorkflow(WorkflowModel saved) {
    state = FlowState(
      model: saved,
      currentQuestionId: null,
      activeBranch: null,
      branchStack: const [],
      userParams: const {},
      undoStack: const [],
    );
  }

  /// Aktif soruda verilen seçeneği uygular (FR-03).
  void answer(int optionIndex) {
    state = _engine.answer(state, optionIndex);
  }

  /// Bir önceki soruya ve modele geri döner (FR-04).
  void undo() {
    if (state.undoStack.isEmpty) return;
    state = _engine.undo(state);
  }

  /// Belirtilen düğümün parametrelerini günceller (FR-11).
  void updateNodeParams(String nodeId, Map<String, dynamic> params) {
    state = _engine.updateParams(state, nodeId, params);
  }

  /// Workflow adını günceller (FR-11).
  void renameWorkflow(String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      model: state.model.copyWith(
        name: trimmed,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

/// Ana akış durumu sağlayıcısı.
final flowControllerProvider = NotifierProvider<FlowController, FlowState>(
  FlowController.new,
);

/// Aktif soruya ait filtrelenmiş seçenek listesi.
final availableOptionsProvider = Provider<List<Option>>((ref) {
  final state = ref.watch(flowControllerProvider);
  final engine = ref.watch(flowEngineProvider);
  return engine.availableOptions(state);
});

/// Kullanıcı parametre düzenlemeleri birleştirilmiş canlı akış modeli (tek doğruluk kaynağı).
final effectiveWorkflowProvider = Provider<WorkflowModel>((ref) {
  final state = ref.watch(flowControllerProvider);
  return state.effectiveModel;
});

/// Canlı yerleşim sonucu — yatay (exporter'lar için: `nodeRects`, `sceneRects`).
final layoutResultProvider = Provider<LayoutResult>((ref) {
  final model = ref.watch(effectiveWorkflowProvider);
  return const AutoLayout().compute(model);
});

/// Mobil önizleme ekranı için yukarıdan aşağıya (dikey) yerleşim sonucu.
final previewLayoutResultProvider = Provider<LayoutResult>((ref) {
  final model = ref.watch(effectiveWorkflowProvider);
  return const AutoLayout().computeVertical(model);
});

/// Canlı doğrulama bulguları (SDD 5.5).
final validationIssuesProvider = Provider<List<ValidationIssue>>((ref) {
  final model = ref.watch(effectiveWorkflowProvider);
  return const Validator().validate(model);
});
