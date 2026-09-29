import '../domain/models/models.dart';

/// Read receipts, derived from `channels/{id}.lastReadAt`.
///
/// A member has seen a message when their last read timestamp is at or after
/// the moment it was sent. The sender is never counted.
List<String> seenBy(Channel channel, Message message) {
  final seen = <String>[];
  for (final uid in channel.memberIds) {
    if (uid == message.senderId) continue;
    final readAt = channel.lastReadAt[uid];
    if (readAt != null && !readAt.isBefore(message.sentAt)) seen.add(uid);
  }
  return seen;
}

/// True when everybody else in the conversation has caught up.
bool seenByAll(Channel channel, Message message) {
  final others = channel.memberIds.where((uid) => uid != message.senderId).length;
  return others > 0 && seenBy(channel, message).length >= others;
}
