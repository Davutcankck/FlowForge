/// Senaryo fikstürü: labelKey sırasıyla verilen cevapların ardından beklenen
/// node anahtarları ve edge'ler (node indeksleri + outputIndex).
class Scenario {
  final String name;
  final List<String> answers;
  final List<String> expectedNodeKeys;
  final List<(int from, int to, int out)> expectedEdges;
  const Scenario({
    required this.name,
    required this.answers,
    required this.expectedNodeKeys,
    required this.expectedEdges,
  });
}

/// Senaryo A: lineer akış (webhook → httpRequest → telegram)
const scenarioLinear = Scenario(
  name: 'linear',
  answers: ['trigger.webhook', 'action.httpRequest', 'cond.none',
            'out.telegram', 'branch.end'],
  expectedNodeKeys: ['webhook', 'httpRequest', 'telegram'],
  expectedEdges: [(0, 1, 0), (1, 2, 0)],
);

/// Senaryo B: IF dallanmalı akış (webhook → httpRequest → IF →
/// googleSheets [true], telegram [false])
const scenarioIfBranch = Scenario(
  name: 'if_branch',
  answers: ['trigger.webhook', 'action.httpRequest', 'cond.if',
            'out.googleSheets', 'branch.end',
            'out.telegram', 'branch.end'],
  expectedNodeKeys: ['webhook', 'httpRequest', 'if', 'googleSheets', 'telegram'],
  expectedEdges: [(0, 1, 0), (1, 2, 0), (2, 3, 0), (2, 4, 1)],
);