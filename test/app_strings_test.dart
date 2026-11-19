import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/l10n/app_strings.dart';
import 'package:flowforge/core/questions/question_flow.dart';

void main() {
  group('AppStrings', () {
    test('AppLang enum tr ve en değerlerini içerir', () {
      expect(AppLang.values, contains(AppLang.tr));
      expect(AppLang.values, contains(AppLang.en));
    });

    test('lookup mevcut anahtar için boş olmayan string döner', () {
      expect(AppStrings.lookup('q_trigger', AppLang.tr), isNotEmpty);
      expect(AppStrings.lookup('q_trigger', AppLang.en), isNotEmpty);
      expect(AppStrings.lookup('trigger.webhook', AppLang.tr), isNotEmpty);
      expect(AppStrings.lookup('trigger.webhook', AppLang.en), isNotEmpty);
    });

    test('eksik anahtar StateError fırlatır ve iletide anahtarı içerir', () {
      expect(
        () => AppStrings.lookup('yoksa_bir_anahtar', AppLang.tr),
        throwsA(predicate((dynamic e) {
          return e is StateError && e.toString().contains('yoksa_bir_anahtar');
        })),
      );
    });

    test('QuestionFlow tüm textKey/labelKey tr+en lookup\'ta mevcut', () {
      for (final q in QuestionFlow.all) {
        for (final lang in AppLang.values) {
          expect(() => AppStrings.lookup(q.textKey, lang), returnsNormally);
          for (final o in q.options) {
            expect(() => AppStrings.lookup(o.labelKey, lang), returnsNormally);
          }
        }
      }
    });
  });
}