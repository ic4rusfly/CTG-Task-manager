enum NotificationKind { message, mention, taskAssigned, taskStatus, dueSoon, eventInvite }

NotificationKind notificationKindFrom(String? value) => NotificationKind.values.firstWhere(
      (k) => k.name == value,
      orElse: () => NotificationKind.message,
    );

/// An entry of `notifications/{uid}/items` — written by the client in mock mode
/// and by Cloud Functions in production.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.uid,
    required this.kind,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String uid;
  final NotificationKind kind;
  final String title;
  final String body;
  final String route;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        uid: uid,
        kind: kind,
        title: title,
        body: body,
        route: route,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'title': title,
        'body': body,
        'route': route,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppNotification.fromMap(String id, String uid, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        uid: uid,
        kind: notificationKindFrom(map['kind'] as String?),
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        route: map['route'] as String? ?? '/chat',
        read: map['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
