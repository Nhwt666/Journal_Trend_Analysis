class Topic {
  final String id;
  final String displayName;
  final String? subfield;
  final String? field;
  final String? domain;
  final double? score;

  const Topic({
    required this.id,
    required this.displayName,
    this.subfield,
    this.field,
    this.domain,
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
      };

  factory Topic.fromJson(Map<String, dynamic> json) {
    final subfield = json['subfield'] as Map<String, dynamic>?;
    final field = json['field'] as Map<String, dynamic>?;
    final domain = json['domain'] as Map<String, dynamic>?;

    return Topic(
      id: (json['id'] as String?) ?? '',
      displayName: (json['display_name'] as String?)?.trim() ?? 'Unknown',
      subfield: subfield?['display_name'] as String?,
      field: field?['display_name'] as String?,
      domain: domain?['display_name'] as String?,
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}
