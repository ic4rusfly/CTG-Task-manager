import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../firebase_options.dart';
import '../../providers/providers.dart';
import 'firebase_auth_repository.dart';
import 'firestore_agenda_repository.dart';
import 'firestore_chat_repository.dart';
import 'firestore_notification_repository.dart';
import 'firestore_task_repository.dart';
import 'firestore_user_repository.dart';

/// Starts Firebase and returns the provider overrides that replace the mock
/// repositories. Nothing else in the app knows Firebase exists.
Future<List<Override>> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final auth = fb.FirebaseAuth.instance;

  if (Env.useEmulator) {
    final host = Env.emulatorHost;
    firestore.useFirestoreEmulator(host, 8080);
    await auth.useAuthEmulator(host, 9099);
  } else {
    // Offline cache: reads work without a connection and writes are queued.
    // Supported on mobile, desktop and web in cloud_firestore 5.x.
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  return [
    authRepositoryProvider.overrideWithValue(
      FirebaseAuthRepository(auth: auth, firestore: firestore),
    ),
    userRepositoryProvider.overrideWithValue(
      FirestoreUserRepository(firestore: firestore),
    ),
    chatRepositoryProvider.overrideWithValue(
      FirestoreChatRepository(firestore: firestore),
    ),
    taskRepositoryProvider.overrideWithValue(
      FirestoreTaskRepository(firestore: firestore),
    ),
    agendaRepositoryProvider.overrideWithValue(
      FirestoreAgendaRepository(firestore: firestore),
    ),
    notificationRepositoryProvider.overrideWithValue(
      FirestoreNotificationRepository(firestore: firestore),
    ),
  ];
}
