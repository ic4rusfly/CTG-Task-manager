/// Device-level push notifications.
///
/// The UI only ever talks to this interface, so the mock build behaves like
/// the real one: it asks for permission, "registers" a device and delivers
/// foreground messages that the app turns into an in-app banner.
enum PushPermission {
  granted,
  denied,

  /// The member has not been asked yet.
  notDetermined,

  /// No push on this platform or build (Linux desktop, mock backend on web).
  unsupported,
}

/// A notification as it reaches the app, already localised by the sender.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.route,
    this.kind = 'message',
  });

  final String title;
  final String body;
  final String route;
  final String kind;

  factory PushMessage.fromData(Map<String, dynamic> data, {String? title, String? body}) =>
      PushMessage(
        title: title ?? data['title'] as String? ?? '',
        body: body ?? data['body'] as String? ?? '',
        route: data['route'] as String? ?? '/notifications',
        kind: data['kind'] as String? ?? 'message',
      );
}

abstract class PushService {
  /// Current permission, without prompting.
  Future<PushPermission> status();

  /// Prompts if needed and stores the device token against [uid].
  Future<PushPermission> register(String uid);

  /// Drops this device's token so a signed-out phone stops buzzing.
  Future<void> unregister(String uid);

  /// Messages that arrive while the app is in the foreground.
  Stream<PushMessage> get foregroundMessages;

  /// Routes to open because the member tapped a notification.
  Stream<String> get openedRoutes;

  Future<String?> currentToken();
}
