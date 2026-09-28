class Team {
  const Team({
    required this.id,
    required this.name,
    this.description = '',
    this.memberIds = const [],
    this.leadId,
    this.colorValue = 0xFF2E4A3A,
  });

  final String id;
  final String name;
  final String description;
  final List<String> memberIds;
  final String? leadId;
  final int colorValue;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'memberIds': memberIds,
        'leadId': leadId,
        'colorValue': colorValue,
      };

  factory Team.fromMap(String id, Map<String, dynamic> map) => Team(
        id: id,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        memberIds: (map['memberIds'] as List?)?.cast<String>() ?? const [],
        leadId: map['leadId'] as String?,
        colorValue: map['colorValue'] as int? ?? 0xFF2E4A3A,
      );
}
