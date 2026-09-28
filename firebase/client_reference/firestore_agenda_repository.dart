import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/domain/models/models.dart';
import '../../lib/domain/repositories/repositories.dart';

class FirestoreAgendaRepository implements AgendaRepository {
  FirestoreAgendaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events => _db.collection('events');

  /// Events from a month back so the calendar can page without refetching.
  @override
  Stream<List<AgendaEvent>> watchEvents() {
    final from = DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
    return _events
        .where('startAt', isGreaterThanOrEqualTo: from)
        .orderBy('startAt')
        .snapshots()
        .map((s) => s.docs.map((d) => AgendaEvent.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<AgendaEvent> createEvent(AgendaEvent event) async {
    final doc = _events.doc();
    final data = event.toMap();
    await doc.set(data);
    return AgendaEvent.fromMap(doc.id, data);
  }

  @override
  Future<void> updateEvent(AgendaEvent event) => _events.doc(event.id).update(event.toMap());

  @override
  Future<void> setRsvp(String eventId, String uid, Rsvp rsvp) =>
      _events.doc(eventId).update({'rsvp.$uid': rsvp.name});

  @override
  Future<void> deleteEvent(String eventId) => _events.doc(eventId).delete();
}
