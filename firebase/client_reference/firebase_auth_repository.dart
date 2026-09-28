import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../lib/domain/models/models.dart';
import '../../lib/domain/repositories/repositories.dart';

/// Firebase Auth + the matching `users/{uid}` profile document.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AppUser? _cached;

  @override
  AppUser? get currentUser => _cached;

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) {
          _cached = null;
          return Stream<AppUser?>.value(null);
        }
        // Profile edits (locale, avatar, role) propagate live.
        return _db.collection('users').doc(user.uid).snapshots().map((doc) {
          if (!doc.exists) return null;
          _cached = AppUser.fromMap(doc.id, doc.data()!);
          return _cached;
        });
      });

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError('not-a-ctg-member');
    }
    final user = AppUser.fromMap(doc.id, doc.data()!);
    if (!user.active) {
      await _auth.signOut();
      throw StateError('user-disabled');
    }
    _cached = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _cached = null;
    await _auth.signOut();
  }
}
