// Placeholder configuration.
//
// Run `flutterfire configure` once the CTG Firebase project exists - it
// overwrites this file with the real, project-specific values. Until then the
// app only builds in mock mode (the default); passing
// --dart-define=BACKEND=firebase throws the message below at startup.
//
// The values generated here are client identifiers, not secrets: they are safe
// to commit, and access is controlled by firebase/firestore.rules.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const bool configured = false;

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet.\n'
      'Run `flutterfire configure` (it regenerates lib/firebase_options.dart), '
      'or run the app without --dart-define=BACKEND=firebase to use the mock data.',
    );
  }
}
