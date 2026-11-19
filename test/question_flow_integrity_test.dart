import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/catalog/node_catalog.dart';
import 'package:flowforge/core/questions/question.dart';
import 'package:flowforge/core/questions/question_flow.dart';

void main() {
  group('Soru ağacı bütünlüğü', () {
    test('tüm nextQuestionId referansları question_flow içinde geçerli', () {
      final ids = <String>{};
      for (final q in QuestionFlow.all) {
        ids.add(q.id);
      }

      for (final q in QuestionFlow.all) {
        for (final o in q.options) {
          if (o.nextQuestionId != null) {
            expect(ids.contains(o.nextQuestionId), isTrue,
                reason: '${q.id} → ${o.nextQuestionId} bulunamadı');
          }
        }
      }
    });

    test('tüm addsNodeKey referansları NodeCatalog içinde geçerli', () {
      final catalogKeys =
          NodeCatalog.all.map((t) => t.key).toSet();

      for (final q in QuestionFlow.all) {
        for (final o in q.options) {
          if (o.addsNodeKey != null) {
            expect(catalogKeys.contains(o.addsNodeKey), isTrue,
                reason: '${q.id} → ${o.addsNodeKey} katalogda yok');
          }
        }
      }
    });

    test('q_condition için cond.none ve cond.if seçenekleri vardır', () {
      final cond = QuestionFlow.byId('q_condition');
      expect(cond, isNotNull);
      final keys = cond!.options.map((o) => o.labelKey).toSet();
      expect(keys.contains('cond.none'), isTrue);
      expect(keys.contains('cond.if'), isTrue);
    });

    test('q_branch_true ve q_branch_false aynı out.* kümesini içersin', () {
      for (final id in ['q_branch_true', 'q_branch_false']) {
        final q = QuestionFlow.byId(id);
        expect(q, isNotNull);
        final keys = q!.options.map((o) => o.labelKey).toSet();
        expect(keys.contains('out.googleSheets'), isTrue);
        expect(keys.contains('out.telegram'), isTrue);
        expect(keys.contains('out.gmail'), isTrue);
        expect(keys.contains('branch.empty'), isTrue);
      }
    });

    test('q_branch_continue seçenekleri: branch.end, action.*, cond.if', () {
      final q = QuestionFlow.byId('q_branch_continue');
      expect(q, isNotNull);
      final keys = q!.options.map((o) => o.labelKey).toSet();
      expect(keys.contains('branch.end'), isTrue);
      expect(keys.any((k) => k.startsWith('action.')), isTrue);
      expect(keys.contains('cond.if'), isTrue);
    });

    test('her Option ya addsNodeKey taşır ya da action\'ı addNode değildir', () {
      for (final q in QuestionFlow.all) {
        for (final o in q.options) {
          if (o.action == OptionAction.addNode) {
            expect(o.addsNodeKey, isNotNull,
                reason: '${q.id}/${o.labelKey}: addNode action\'da addsNodeKey zorunlu');
          }
        }
      }
    });

    test('nextQuestionId == null yalnızca endBranch için geçerlidir', () {
      for (final q in QuestionFlow.all) {
        for (final o in q.options) {
          if (o.nextQuestionId == null) {
            expect(o.action, OptionAction.endBranch,
                reason: '${q.id}/${o.labelKey}: nextQuestionId null sadece endBranch için');
          }
        }
      }
    });
  });
}
