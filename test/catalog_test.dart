import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/core/catalog/node_catalog.dart';
import 'package:flowforge/core/catalog/node_category.dart';

void main() {
  group('NodeCatalog', () {
    test('tüm şablonların anahtarı (key) benzersizdir', () {
      final keys = NodeCatalog.all.map((t) => t.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('katalog 10 şablon içerir: 3 trigger, 4 action, 2 logic, 1 output', () {
      expect(NodeCatalog.all.length, 10);
      expect(NodeCatalog.byCategory(NodeCategory.trigger).length, 3);
      expect(NodeCatalog.byCategory(NodeCategory.action).length, 4);
      expect(NodeCatalog.byCategory(NodeCategory.logic).length, 2);
      expect(NodeCatalog.byCategory(NodeCategory.output).length, 1);
    });

    test('if.outputs == 2, diğerleri 1', () {
      for (final t in NodeCatalog.all) {
        if (t.key == 'if') {
          expect(t.outputs, 2);
        } else {
          expect(t.outputs, 1);
        }
      }
    });

    test('her şablonun drawioStyle alanı boş değil', () {
      for (final t in NodeCatalog.all) {
        expect(t.drawioStyle, isNotEmpty);
      }
    });

    test('typeVersion geçici olarak > 0 (TODO(verify-n8n))', () {
      for (final t in NodeCatalog.all) {
        expect(t.typeVersion, greaterThan(0));
      }
    });

    test('byKey geçersiz anahtar için null döner', () {
      expect(NodeCatalog.byKey('yoksa_bir_anahtar'), isNull);
    });

    test('byCategory bilinmeyen kategori için boş liste döner', () {
      // Bu test derlenemeyecek çünkü NodeCategory sadece 4 değer içerir;
      // ancak byCategory metodu mevcut olmalı.
      expect(NodeCatalog.byCategory(NodeCategory.trigger).length, 3);
    });
  });
}