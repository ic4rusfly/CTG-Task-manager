/// Build-time configuration.
///
/// The app ships with the in-memory mock backend so it runs with no setup:
///
///   flutter run                                   -> mock data
///   flutter run --dart-define=BACKEND=firebase    -> real Firebase project
///   flutter run --dart-define=BACKEND=firebase \
///               --dart-define=USE_EMULATOR=true   -> local emulator suite
class Env {
  const Env._();

  static const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');

  static const useEmulator =
      bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

  /// Host the emulators are reachable at. Android emulators need 10.0.2.2.
  static const emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

  /// Web push needs the project's VAPID public key:
  ///   flutter run -d chrome --dart-define=BACKEND=firebase \
  ///               --dart-define=VAPID_KEY=BFx...
  static const vapidKey = String.fromEnvironment('VAPID_KEY', defaultValue: '');

  static bool get useFirebase => backend == 'firebase';
}
