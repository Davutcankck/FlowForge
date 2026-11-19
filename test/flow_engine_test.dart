import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/catalog/node_catalog.dart';
import 'package:flowforge/core/catalog/node_category.dart';
import 'package:flowforge/core/models/id_generator.dart';
import 'package:flowforge/core/questions/flow_engine.dart';
import 'package:flowforge/core/questions/flow_state.dart';
import 'package:flowforge/core/questions/question.dart';
import 'fixtures/answer_key_helper.dart';
import 'fixtures/scenarios.dart';


    test('answer geçersiz indexte StateError fırlatır', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      var state = engine.start();
      final options = engine.availableOptions(state);

      expect(() => engine.answer(state, options.length),
          throwsA(isA<StateError>()));
      expect(() => engine.answer(state, -1),
          throwsA(isA<StateError>()));
    });

    test('answer bitmiş akışta (currentQuestionId == null) StateError fırlatır',
        () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      var state = engine.start();

      for (final label in scenarioLinear.answers) {
        final options = engine.availableOptions(state);
        final idx = answerKey(options, label);
        state = engine.answer(state, idx);
      }

      expect(state.currentQuestionId, isNull);
      expect(() => engine.answer(state, 0), throwsA(isA<StateError>()));
    });

    test('model.nodes add() UnsupportedError fırlatır', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      final state = engine.start();

      expect(() => state.model.nodes.add(any), throwsUnsupportedError);
    });

    test('Senaryo A: lineer akış 3 node, 2 edge, akış biter', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      _runScenarioAndVerify(engine, scenarioLinear);
    });

    test('Senaryo B: IF dallanmalı 5 node, 4 edge', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      _runScenarioAndVerify(engine, scenarioIfBranch);
    });

    test('Undo: n cevap sonrası k undo → (n-k) cevaplık state ile eşleşir', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      var state = engine.start();
      final states = <FlowState>[state];

      for (final label in scenarioIfBranch.answers) {
        final options = engine.availableOptions(state);
        final idx = answerKey(options, label);
        state = engine.answer(state, idx);
        states.add(state);
      }

      final full = states.last;
      for (var k = 1; k <= states.length - 1; k++) {
        var undone = full;
        for (var i = 0; i < k; i++) {
          undone = engine.undo(undone);
        }
        expect(undone.toJson(), states[states.length - 1 - k].toJson());
      }

      for (final s in states) {
        final triggerCount = s.model.nodes
            .where((n) => NodeCatalog.byKey(n.templateKey)?.category ==
                NodeCategory.trigger)
            .length;
        expect(s.model.edges.length, s.model.nodes.length - triggerCount);
      }
    });

    test('Senaryo B: 5. cevap sonrası undo → activeBranch ve branchStack', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      var state = engine.start();

      for (var i = 0; i < 5; i++) {
        final options = engine.availableOptions(state);
        final label = scenarioIfBranch.answers[i];
        final idx = answerKey(options, label);
        state = engine.answer(state, idx);
      }

      final ifNode = state.model.nodes.firstWhere((n) => n.templateKey == 'if');
      expect(state.activeBranch, isNotNull);
      expect(state.activeBranch!.nodeId, ifNode.id);
      expect(state.activeBranch!.outputIndex, 1);
      expect(state.branchStack, isEmpty);

      final undone = engine.undo(state);
      final gsNode = state.model.nodes
          .firstWhere((n) => n.templateKey == 'googleSheets');
      expect(undone.activeBranch!.nodeId, gsNode.id);
      expect(undone.activeBranch!.outputIndex, 0);
      expect(undone.branchStack.length, 1);
      expect(undone.branchStack.first.nodeId, ifNode.id);
      expect(undone.branchStack.first.outputIndex, 1);
    });

FlowState _go(FlowEngine e, FlowState s, List<String> labels) {
  for (final l in labels) {
    s = e.answer(s, answerKey(e.availableOptions(s), l));
  }
  return s;
}

bool _hasIf(FlowEngine e, FlowState s) =>
    e.availableOptions(s).any((o) => o.labelKey == 'cond.if');

class SequentialIdGenerator implements IdGenerator {
  int _counter = 0;
  @override
  String next() {
    _counter++;
    return 'id-$_counter';
  }
}

void _runScenarioAndVerify(FlowEngine engine, Scenario scenario) {
  var state = engine.start();

  for (final label in scenario.answers) {
    final options = engine.availableOptions(state);
    final idx = answerKey(options, label);
    state = engine.answer(state, idx);
  }

  expect(state.currentQuestionId, isNull);
  expect(state.activeBranch, isNull);
  expect(state.branchStack, isEmpty);

  final actualKeys =
      state.model.nodes.map((n) => n.templateKey).toList();
  expect(actualKeys, scenario.expectedNodeKeys);

  final actualEdges = state.model.edges.map((e) {
    final fromIdx = state.model.nodes.indexWhere((n) => n.id == e.fromId);
    final toIdx = state.model.nodes.indexWhere((n) => n.id == e.toId);
    return (fromIdx, toIdx, e.outputIndex);
  }).toList();
  expect(actualEdges, scenario.expectedEdges);
}

void main() {
  group('FlowEngine', () {
    test('start() ilk soruyu q_trigger döndürür ve model boştur', () {
      final gen = SequentialIdGenerator();
      final engine = FlowEngine(gen: gen);
      final state = engine.start();

      expect(state.currentQuestionId, 'q_trigger');
      expect(state.model.nodes, isEmpty);
      expect(state.model.edges, isEmpty);
      expect(state.activeBranch, isNull);
      expect(state.branchStack, isEmpty);
    });

    // NOT: FlowState.toJson undoStack'i içermemelidir.
    // undo() dönen state'in undoStack'i, kalan kayıtlarla yeniden kurulur
    // (geçmişin kopyası olarak değil, mevcut undoStack'in sonundan devam eder).

    test('İç içe IF: 3 seviye sonra cond.if gizli', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(),
          ['trigger.webhook', 'action.none', 'cond.if', 'out.telegram']);
      expect(s.currentQuestionId, 'q_branch_continue');
      expect(_hasIf(e, s), isTrue);                       // derinlik 1
      s = _go(e, s, ['cond.if', 'out.telegram']);
      expect(_hasIf(e, s), isTrue);                       // derinlik 2
      s = _go(e, s, ['cond.if', 'out.telegram']);
      expect(s.currentQuestionId, 'q_branch_continue');
      expect(_hasIf(e, s), isFalse);                      // derinlik 3
    });

    test('İç içe IF: pop sonrası derinlik ata sayısından hesaplanır', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(), [
        'trigger.webhook', 'action.none',
        'cond.if', 'out.telegram', 'cond.if', 'out.telegram',
        'cond.if', 'out.telegram',
      ]);
      expect(_hasIf(e, s), isFalse);                      // derinlik 3
      s = _go(e, s, ['branch.end']);                      // IF3 false dalı
      expect(s.currentQuestionId, 'q_branch_false');
      s = _go(e, s, ['out.telegram']);
      expect(s.currentQuestionId, 'q_branch_continue');
      expect(_hasIf(e, s), isFalse);                      // hâlâ 3 IF atası var
      s = _go(e, s, ['branch.end']);                      // IF2 false dalı
      s = _go(e, s, ['out.telegram']);
      expect(_hasIf(e, s), isTrue);                       // derinlik 2
    });

    test('branch.empty q_branch_true: node eklemez, dalı bitirir', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(),
          ['trigger.webhook', 'action.httpRequest', 'cond.if']);
      expect(s.currentQuestionId, 'q_branch_true');
      final ifId = s.model.nodes.last.id;
      final n = s.model.nodes.length;
      expect(s.branchStack.length, 1);
      s = _go(e, s, ['branch.empty']);
      expect(s.model.nodes.length, n);
      expect(s.branchStack, isEmpty);
      expect(s.activeBranch!.nodeId, ifId);
      expect(s.activeBranch!.outputIndex, 1);
      expect(s.currentQuestionId, 'q_branch_false');
    });

    test('branch.end ile branch.empty aynı sonuç, tek fark eklenen node', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      final base = _go(e, e.start(),
          ['trigger.webhook', 'action.httpRequest', 'cond.if']);
      final empty = _go(e, base, ['branch.empty']);
      final ended = _go(e, base, ['out.telegram', 'branch.end']);
      expect(ended.model.nodes.length, empty.model.nodes.length + 1);
      expect(ended.activeBranch!.nodeId, empty.activeBranch!.nodeId);
      expect(ended.activeBranch!.outputIndex, empty.activeBranch!.outputIndex);
      expect(ended.branchStack, empty.branchStack);
      expect(ended.currentQuestionId, empty.currentQuestionId);
    });

    test('branch.empty q_branch_false\'da (yığın boş) akışı bitirir', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(),
          ['trigger.webhook', 'action.httpRequest', 'cond.if',
           'out.telegram', 'branch.end']);
      s = _go(e, s, ['branch.empty']);
      expect(s.currentQuestionId, isNull);
      expect(s.activeBranch, isNull);
      expect(s.branchStack, isEmpty);
    });


    test('undo: silinen node params temizlenir, kalan node düzenlemesi korunur', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(), ['trigger.webhook']);
      final webhookId = s.model.nodes.last.id;
      s = e.updateParams(s, webhookId, {'path': 'my-hook'});
      s = _go(e, s, ['action.httpRequest']);
      final httpId = s.model.nodes.last.id;
      s = e.updateParams(s, httpId, {'url': 'https://example.com'});
      s = e.updateParams(s, webhookId, {'path': 'changed'});
      s = _go(e, s, ['cond.none', 'out.telegram']);
      for (var i = 0; i < 3; i++) {
        s = e.undo(s);              // telegram, cond.none, action.httpRequest
      }
      expect(s.model.nodes.any((n) => n.id == httpId), isFalse);
      expect(s.userParams.containsKey(httpId), isFalse);
      expect(s.userParams[webhookId], {'path': 'changed'});
    });

    test('answer sonrası model.nodes ve edges değiştirilemez', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      final after = _go(e, e.start(),
          ['trigger.webhook', 'action.httpRequest']);
      expect(() => after.model.nodes.removeLast(), throwsUnsupportedError);
      expect(() => after.model.edges.removeLast(), throwsUnsupportedError);
    });

    test('undoStack 50 sınırı: 60 action.* cevabı sonrası uzunluk 50', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(),
          ['trigger.webhook', 'action.httpRequest', 'cond.none', 'out.telegram']);
      expect(s.currentQuestionId, 'q_branch_continue');
      for (var i = 0; i < 60; i++) {
        s = _go(e, s, ['action.httpRequest']);
      }
      expect(s.undoStack.length, 50);
    });

    test('Option.action alanı: action.none → skipToCondition, q_condition\'a geçiş', () {
      final e = FlowEngine(gen: SequentialIdGenerator());
      var s = _go(e, e.start(), ['trigger.webhook']);
      final options = e.availableOptions(s);
      final noneOption = options.firstWhere((o) => o.labelKey == 'action.none');
      expect(noneOption.action, OptionAction.skipToCondition);
      s = e.answer(s, answerKey(options, 'action.none'));
      expect(s.currentQuestionId, 'q_condition');
    });
  });
}
