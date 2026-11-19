import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/core/questions/flow_engine.dart';
import 'package:flowforge/core/questions/flow_state.dart';
import 'package:flowforge/core/questions/question.dart';
import 'fixtures/answer_key_helper.dart';

void main() {
  group('FlowEngine Edge Cases', () {
    test('undo() boş yığında StateError fırlatır', () {
      final engine = FlowEngine(gen: SequentialIdGenerator());
      final state = engine.start();
      expect(state.undoStack, isEmpty);
      expect(() => engine.undo(state), throwsA(isA<StateError>()));
    });

    test('updateParams() bilinmeyen nodeId için StateError fırlatır', () {
      final engine = FlowEngine(gen: SequentialIdGenerator());
      final state = engine.start();
      expect(
        () => engine.updateParams(state, 'nonexistent-id', {'k': 'v'}),
        throwsA(isA<StateError>()),
      );
    });

    test('availableOptions() biten akışta (currentQuestionId == null) boş liste döner', () {
      final engine = FlowEngine(gen: SequentialIdGenerator());
      var state = engine.start();
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'trigger.webhook'));
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'action.none'));
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'cond.none'));
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'out.telegram'));
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'branch.end'));

      expect(state.currentQuestionId, isNull);
      expect(engine.availableOptions(state), isEmpty);
    });

    test('FlowState.effectiveModel: model node parametrelerinin üzerine userParams birleştirilmiş yeni model döner', () {
      final engine = FlowEngine(gen: SequentialIdGenerator());
      var state = engine.start();
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'trigger.webhook'));
      final nodeId = state.model.nodes.first.id;

      state = engine.updateParams(state, nodeId, {'customParam': '123'});

      final effective = state.effectiveModel;
      expect(effective.nodeById(nodeId)?.parameters['customParam'], '123');
      expect(effective.nodeById(nodeId)?.parameters['path'], 'my-hook');
      expect(state.model.nodeById(nodeId)?.parameters.containsKey('customParam'), isFalse);
    });

    test('updateParams merge: yeni anahtar eskiyi ezer, mevcutları korur', () {
      final engine = FlowEngine(gen: SequentialIdGenerator());
      var state = engine.start();
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'trigger.webhook'));
      final nodeId = state.model.nodes.first.id;

      state = engine.updateParams(state, nodeId, {'a': 1, 'b': 2});
      state = engine.updateParams(state, nodeId, {'b': 99, 'c': 3});

      expect(state.userParams[nodeId], {'a': 1, 'b': 99, 'c': 3});
    });

    test('BranchCursor value semantics ve serileştirme', () {
      const c1 = BranchCursor(nodeId: 'n1', outputIndex: 0);
      const c2 = BranchCursor(nodeId: 'n1', outputIndex: 0);
      const c3 = BranchCursor(nodeId: 'n2', outputIndex: 1);

      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1 == c3, isFalse);
      expect(c1.toString(), contains('n1'));

      final json = c1.toJson();
      final restored = BranchCursor.fromJson(json);
      expect(restored, c1);
    });

    test('FlowState toJson ve fromJson serileştirme', () {
      final engine = FlowEngine(gen: SequentialIdGenerator());
      var state = engine.start();
      state = engine.answer(state, answerKey(engine.availableOptions(state), 'trigger.webhook'));

      final json = state.toJson();
      final restored = FlowState.fromJson(json);

      expect(restored.currentQuestionId, state.currentQuestionId);
      expect(restored.model.nodes.length, state.model.nodes.length);
      expect(restored.activeBranch, state.activeBranch);
      expect(restored.undoStack, isEmpty);
    });

    test('Question ve Option value semantics', () {
      const o1 = Option(labelKey: 'k', action: OptionAction.goNext);
      const o2 = Option(labelKey: 'k', action: OptionAction.goNext);
      const o3 = Option(labelKey: 'k2', action: OptionAction.endBranch);

      expect(o1, o2);
      expect(o1.hashCode, o2.hashCode);
      expect(o1 == o3, isFalse);
      expect(o1.toString(), contains('k'));

      final q1 = Question(id: 'q1', textKey: 't1', options: const [o1]);
      final q2 = Question(id: 'q1', textKey: 't1', options: const [o1]);
      final q3 = Question(id: 'q2', textKey: 't2', options: const [o3]);

      expect(q1, q2);
      expect(q1.hashCode, q2.hashCode);
      expect(q1 == q3, isFalse);
      expect(q1.toString(), contains('q1'));
    });
  });
}
