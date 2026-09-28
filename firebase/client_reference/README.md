# Phase 1 — swapping the mocks for Firebase

These files are **not compiled** (they are excluded in `analysis_options.yaml`).
They are the reference implementations to move into `lib/data/firebase/` when the
Firebase project exists.

Steps:

1. `flutterfire configure` → generates `lib/firebase_options.dart`.
2. Uncomment the Firebase dependencies in `pubspec.yaml`, then `flutter pub get`.
3. Move `firestore_task_repository.dart` and `firestore_chat_repository.dart`
   into `lib/data/firebase/` (the users and agenda repositories follow exactly
   the same shape).
4. In `lib/main.dart`, initialise Firebase and override the providers:

```dart
runApp(ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(FirebaseAuthRepository()),
    userRepositoryProvider.overrideWithValue(FirestoreUserRepository()),
    chatRepositoryProvider.overrideWithValue(FirestoreChatRepository()),
    taskRepositoryProvider.overrideWithValue(FirestoreTaskRepository()),
    agendaRepositoryProvider.overrideWithValue(FirestoreAgendaRepository()),
  ],
  child: const CtgApp(),
));
```

5. `firebase deploy --only firestore:rules,firestore:indexes,storage`.

Nothing in `lib/features/**` changes — the UI only knows the interfaces in
`lib/domain/repositories/repositories.dart`.
