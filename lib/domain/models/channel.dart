import 'enums.dart';

class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.type,
    this.topic = '',
    this.memberIds = const [],
    this.createdBy,
    this.lastMessageText = '',
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastReadAt = const {},
    this.muted = false,
  });

  final String id;
  final String name;
  final ChannelType type;
  final String topic;
  final List<String> memberIds;
  final String? createdBy;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, DateTime> lastReadAt;
  final bool muted;

  bool get isDm => type == ChannelType.dm || type == ChannelType.groupDm;

  /// The other participant of a 1-to-1 conversation.
  String? peerOf(String uid) =>
      type == ChannelType.dm ? memberIds.firstWhere((m) => m != uid, orElse: () => uid) : null;

  Channel copyWith({
    String? name,
    String? topic,
    List<String>? memberIds,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    Map<String, DateTime>? lastReadAt,
    bool? muted,
  }) =>
      Channel(
        id: id,
        name: name ?? this.name,
        type: type,
        topic: topic ?? this.topic,
        memberIds: memberIds ?? this.memberIds,
        createdBy: createdBy,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
        lastReadAt: lastReadAt ?? this.lastReadAt,
        muted: muted ?? this.muted,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.name,
        'topic': topic,
        'memberIds': memberIds,
        'createdBy': createdBy,
        'lastMessage': {
          'text': lastMessageText,
          'senderId': lastMessageSenderId,
          'sentAt': lastMessageAt?.toIso8601String(),
        },
        'lastReadAt': lastReadAt.map((k, v) => MapEntry(k, v.toIso8601String())),
        'muted': muted,
      };

  factory Channel.fromMap(String id, Map<String, dynamic> map) {
    final last = (map['lastMessage'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Channel(
      id: id,
      name: map['name'] as String? ?? '',
      type: channelTypeFrom(map['type'] as String?),
      topic: map['topic'] as String? ?? '',
      memberIds: (map['memberIds'] as List?)?.cast<String>() ?? const [],
      createdBy: map['createdBy'] as String?,
      lastMessageText: last['text'] as String? ?? '',
      lastMessageSenderId: last['senderId'] as String?,
      lastMessageAt: DateTime.tryParse(last['sentAt'] as String? ?? ''),
      lastReadAt: ((map['lastReadAt'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, DateTime.tryParse('$v') ?? DateTime(1970)),
      ),
      muted: map['muted'] as bool? ?? false,
    );
  }
}
