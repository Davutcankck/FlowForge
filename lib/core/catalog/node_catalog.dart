import 'actions.dart';
import 'logic.dart';
import 'node_category.dart';
import 'node_template.dart';
import 'outputs.dart';
import 'triggers.dart';

/// Desteklenen tüm node şablonlarını içeren katalog.
abstract final class NodeCatalog {
  static final List<NodeTemplate> all = List.unmodifiable(<NodeTemplate>[
    ...triggerTemplates,
    ...actionTemplates,
    ...logicTemplates,
    ...outputTemplates,
  ]);

  static final Map<String, NodeTemplate> _byKey = {
    for (final template in all) template.key: template,
  };

  /// [key] değerine sahip şablonu döndürür, yoksa `null`.
  static NodeTemplate? byKey(String key) => _byKey[key];

  /// [category] kategorisindeki tüm şablonların değiştirilemez listesini döndürür.
  static List<NodeTemplate> byCategory(NodeCategory category) {
    return List.unmodifiable(all.where((t) => t.category == category));
  }
}
