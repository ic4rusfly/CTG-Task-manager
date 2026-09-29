import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Reads `notifications/{uid}/items`, which Cloud Functions write (already
/// localised to the recipient's language).
class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('notifications').doc(uid).collection('items');

  @override
  Stream<List<AppNotification>> watch(String uid) => _items(uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => AppNotification.fromMap(d.id, uid, d.data())).toList());

  @override
  Future<void> add(AppNotification notification) =>
      _items(notification.uid).add(notification.toMap());

  @override
  Future<void> markRead(String uid, String id) => _items(uid).doc(id).update({'read': true});

  @override
  Future<void> markAllRead(String uid) async {
    final snap = await _items(uid).where('read', isEqualTo: false).limit(400).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
