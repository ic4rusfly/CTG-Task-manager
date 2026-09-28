import 'attachment.dart';
import 'enums.dart';

class Message {
  const Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.sentAt,
    this.type = MessageType.text,
    this.text = '',
    this.attachments = const [],
    this.taskId,
    this.linkUrl,
    this.replyToId,
    this.threadCount = 0,
    this.reactions = const {},
    this.mentions = const [],
    this.editedAt,
    this.deleted = false,
  });

  final String id;
  final String channelId;
  final String senderId;
  final DateTime sentAt;
  final MessageType type;
  final String text;
  final List<Attachment> attachments;
  final String? taskId;
  final String? linkUrl;
  final String? replyToId;
  final int threadCount;
  final Map<String, List<String>> reactions;
  final List<String> mentions;
  final DateTime? editedAt;
  final bool deleted;

  Message copyWith({
    String? text,
    Map<String, List<String>>? reactions,
    int? threadCount,
    DateTime? editedAt,
    bool? deleted,
  }) =>
      Message(
        id: id,
        channelId: channelId,
        senderId: senderId,
        sentAt: sentAt,
        type: type,
        text: text ?? this.text,
        attachments: attachments,
        taskId: taskId,
        linkUrl: linkUrl,
        replyToId: replyToId,
        threadCount: threadCount ?? this.threadCount,
        reactions: reactions ?? this.reactions,
        mentions: mentions,
        editedAt: editedAt ?? this.editedAt,
        deleted: deleted ?? this.deleted,
      );

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'sentAt': sentAt.toIso8601String(),
        'type': type.name,
        'text': text,
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'taskId': taskId,
        'linkUrl': linkUrl,
        'replyToId': replyToId,
        'threadCount': threadCount,
        'reactions': reactions,
        'mentions': mentions,
        'editedAt': editedAt?.toIso8601String(),
        'deleted': deleted,
      };

  factory Message.fromMap(String id, String channelId, Map<String, dynamic> map) => Message(
        id: id,
        channelId: channelId,
        senderId: map['senderId'] as String? ?? '',
        sentAt: DateTime.tryParse(map['sentAt'] as String? ?? '') ?? DateTime.now(),
        type: messageTypeFrom(map['type'] as String?),
        text: map['text'] as String? ?? '',
        attachments: ((map['attachments'] as List?) ?? const [])
            .map((a) => Attachment.fromMap((a as Map).cast<String, dynamic>()))
            .toList(),
        taskId: map['taskId'] as String?,
        linkUrl: map['linkUrl'] as String?,
        replyToId: map['replyToId'] as String?,
        threadCount: map['threadCount'] as int? ?? 0,
        reactions: ((map['reactions'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as List).cast<String>()),
        ),
        mentions: (map['mentions'] as List?)?.cast<String>() ?? const [],
        editedAt: DateTime.tryParse(map['editedAt'] as String? ?? ''),
        deleted: map['deleted'] as bool? ?? false,
      );
}
