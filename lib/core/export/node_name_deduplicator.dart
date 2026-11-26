import '../models/workflow_model.dart';

/// Akış içindeki düğüm adlarını deterministik biçimde tekilleştirir (SDD 5.3 & V-05).
///
/// Kural:
/// - İlk görülen ad aynen korunur (örn. `"HTTP Request"`).
/// - Tekrar eden adlara sırayla sayısal son ek eklenir (`"HTTP Request1"`, `"HTTP Request2"`, ...).
/// - Eğer modelde zaten `"HTTP Request1"` adında başka bir düğüm varsa o ad
///   korunur ve çakışma olmadan bir sonraki boş sayıya (`"HTTP Request2"`) geçilir.
Map<String, String> resolveUniqueNames(WorkflowModel model) {
  final result = <String, String>{};
  final usedNames = <String>{};

  // Henüz işlenmemiş düğümlerin orijinal adlarını sayarak, daha sonra gelecek
  // tekil bir adla (örn. önceden "HTTP Request1" verilmiş bir düğümle) çakışmayı önle.
  final remainingNameCounts = <String, int>{};
  for (final node in model.nodes) {
    remainingNameCounts[node.name] = (remainingNameCounts[node.name] ?? 0) + 1;
  }

  for (final node in model.nodes) {
    final currentCount = remainingNameCounts[node.name] ?? 0;
    if (currentCount <= 1) {
      remainingNameCounts.remove(node.name);
    } else {
      remainingNameCounts[node.name] = currentCount - 1;
    }

    if (!usedNames.contains(node.name)) {
      usedNames.add(node.name);
      result[node.id] = node.name;
      continue;
    }

    var suffix = 1;
    var candidate = '${node.name}$suffix';
    while (usedNames.contains(candidate) ||
        remainingNameCounts.containsKey(candidate)) {
      suffix++;
      candidate = '${node.name}$suffix';
    }

    usedNames.add(candidate);
    result[node.id] = candidate;
  }

  return result;
}

/// [resolveUniqueNames] sonucunu modele uygulayarak benzersiz adlara sahip yeni
/// bir [WorkflowModel] döndürür.
WorkflowModel applyUniqueNames(WorkflowModel model) {
  final nameMap = resolveUniqueNames(model);
  final updatedNodes = model.nodes
      .map((node) => node.copyWith(name: nameMap[node.id] ?? node.name))
      .toList();
  return model.copyWith(nodes: updatedNodes);
}
