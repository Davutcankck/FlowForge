/// İki node arasındaki bağlantı.
///
/// [outputIndex] kaynak şablonun çıkış indeksidir (IF: 0 = true, 1 = false).
class WorkflowEdge {
  const WorkflowEdge({
    required this.fromId,
    required this.toId,
    required this.outputIndex,
  });

  final String fromId;
  final String toId;
  final int outputIndex;

  WorkflowEdge copyWith({
    String? fromId,
    String? toId,
    int? outputIndex,
  }) {
    return WorkflowEdge(
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      outputIndex: outputIndex ?? this.outputIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'outputIndex': outputIndex,
    };
  }

  factory WorkflowEdge.fromJson(Map<String, dynamic> json) {
    return WorkflowEdge(
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      outputIndex: json['outputIndex'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowEdge &&
        other.fromId == fromId &&
        other.toId == toId &&
        other.outputIndex == outputIndex;
  }

  @override
  int get hashCode => Object.hash(fromId, toId, outputIndex);

  @override
  String toString() {
    return 'WorkflowEdge(fromId: $fromId, toId: $toId, outputIndex: $outputIndex)';
  }
}