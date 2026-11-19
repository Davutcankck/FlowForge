import 'package:flowforge/core/questions/question.dart';

/// [labelKey] değerine karşılık gelen seçeneğin [optionIndex]'ini döndürür.
/// Test senaryolarında labelKey üzerinden doğru seçeneği bulmak için kullanılır.
int answerKey(List<Option> options, String labelKey) {
  for (var i = 0; i < options.length; i++) {
    if (options[i].labelKey == labelKey) return i;
  }
  throw StateError('labelKey bulunamadı: $labelKey');
}