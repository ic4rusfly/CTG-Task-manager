import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<AppUser>> watchUsers() => _db
      .collection('users')
      .orderBy('displayName')
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<Team>> watchTeams() => _db
      .collection('teams')
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => Team.fromMap(d.id, d.data())).toList());

  @override
  Future<AppUser?> getUser(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    return doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null;
  }

  @override
  Future<void> updateProfile(AppUser user) => _db
      .collection('users')
      .doc(user.id)
      .set(user.toMap()..remove('role')..remove('active'), SetOptions(merge: true));

  @override
  Future<void> setLocale(String uid, String locale) =>
      _db.collection('users').doc(uid).update({'locale': locale});

  // Role and active flags are admin-only; the rules reject anyone else and the
  // onUserRoleChange function refreshes the custom claims.
  @override
  Future<void> setRole(String uid, UserRole role) =>
      _db.collection('users').doc(uid).update({'role': role.name});

  @override
  Future<void> setActive(String uid, bool active) =>
      _db.collection('users').doc(uid).update({'active': active});
}
