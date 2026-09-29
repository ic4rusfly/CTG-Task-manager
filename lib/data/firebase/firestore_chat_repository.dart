import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/search_tokens.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Firestore implementation of [ChatRepository].
class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _channels => _db.collection('channels');

  @override
  Stream<List<Channel>> watchChannels(String uid) => _channels
      .where('memberIds', arrayContains: uid)
      .orderBy('lastMessage.sentAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Channel.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<Message>> watchMessages(String channelId, {int limit = 100}) => _channels
      .doc(channelId)
      .collection('messages')
      .orderBy('sentAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.reversed
          .map((d) => Message.fromMap(d.id, channelId, d.data()))
          .toList());

  @override
  Stream<List<Message>> watchThread(String channelId, String rootId) => _channels
      .doc(channelId)
      .collection('messages')
      .where('replyToId', isEqualTo: rootId)
      .orderBy('sentAt')
      .snapshots()
      .map((s) => s.docs.map((d) => Message.fromMap(d.id, channelId, d.data())).toList());

  @override
  Future<void> sendMessage(Message message) async {
    final batch = _db.batch();
    final msgRef = _channels.doc(message.channelId).collection('messages').doc();
    batch.set(msgRef, message.toMap());
    batch.update(_channels.doc(message.channelId), {
      'lastMessage': {
        'text': message.text,
        'senderId': message.senderId,
        'sentAt': message.sentAt.toIso8601String(),
      },
    });
    // Keep the "N replies" counter on the root message up to date.
    final rootId = message.replyToId;
    if (rootId != null) {
      batch.update(
        _channels.doc(message.channelId).collection('messages').doc(rootId),
        {'threadCount': FieldValue.increment(1)},
      );
    }
    await batch.commit();
  }

  @override
  Future<void> toggleReaction(
      String channelId, String messageId, String emoji, String uid) async {
    final ref = _channels.doc(channelId).collection('messages').doc(messageId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final reactions = Map<String, dynamic>.from(snap.data()?['reactions'] ?? {});
      final users = List<String>.from(reactions[emoji] ?? const <String>[]);
      users.contains(uid) ? users.remove(uid) : users.add(uid);
      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }
      tx.update(ref, {'reactions': reactions});
    });
  }

  @override
  Future<void> editMessage(String channelId, String messageId, String text) => _channels
      .doc(channelId)
      .collection('messages')
      .doc(messageId)
      .update({'text': text, 'editedAt': DateTime.now().toIso8601String()});

  /// One indexed collection-group query per batch of 30 conversations
  /// (Firestore caps `whereIn`), then an exact check on the full phrase.
  @override
  Future<List<Message>> searchMessages({
    required String query,
    required List<String> channelIds,
    int limit = 50,
  }) async {
    final token = queryToken(query);
    if (token == null || channelIds.isEmpty) return const [];

    final hits = <Message>[];
    for (var i = 0; i < channelIds.length; i += 30) {
      final batch = channelIds.sublist(i, (i + 30).clamp(0, channelIds.length));
      final snap = await _db
          .collectionGroup('messages')
          .where('keywords', arrayContains: token)
          .where('channelId', whereIn: batch)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final message = Message.fromMap(
          doc.id,
          data['channelId'] as String? ?? '',
          data,
        );
        if (message.deleted) continue;
        if (matchesQuery(message.searchable, query)) hits.add(message);
      }
    }
    hits.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return hits.length <= limit ? hits : hits.sublist(0, limit);
  }

  @override
  Future<void> deleteMessage(String channelId, String messageId) => _channels
      .doc(channelId)
      .collection('messages')
      .doc(messageId)
      .update({'deleted': true, 'text': ''});

  @override
  Future<void> markRead(String channelId, String uid) => _channels
      .doc(channelId)
      .set({'lastReadAt': {uid: DateTime.now().toIso8601String()}}, SetOptions(merge: true));

  @override
  Future<Channel> createChannel({
    required String name,
    required ChannelType type,
    required List<String> memberIds,
    String topic = '',
    String? createdBy,
  }) async {
    final doc = _channels.doc();
    final data = {
      'name': name,
      'type': type.name,
      'topic': topic,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'lastMessage': {'text': '', 'senderId': null, 'sentAt': DateTime.now().toIso8601String()},
    };
    await doc.set(data);
    return Channel.fromMap(doc.id, data);
  }

  @override
  Future<Channel> openDm(String uid, String peerId) async {
    final query = await _channels
        .where('type', isEqualTo: ChannelType.dm.name)
        .where('memberIds', arrayContains: uid)
        .get();
    for (final doc in query.docs) {
      final members = List<String>.from(doc.data()['memberIds'] as List);
      if (members.length == 2 && members.contains(peerId)) {
        return Channel.fromMap(doc.id, doc.data());
      }
    }
    return createChannel(
      name: '',
      type: ChannelType.dm,
      memberIds: [uid, peerId],
      createdBy: uid,
    );
  }
}
