import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/env.dart';
import '../../domain/push_service.dart';

/// Handles notifications that arrive while the app is terminated or in the
/// background. It must be a top-level function.
@pragma('vm:entry-point')
Future<void> ctgBackgroundMessageHandler(RemoteMessage message) async {
  // The payload is already localised and stored in Firestore by the Cloud
  // Functions, so the background isolate has nothing to do; the system tray
  // notification is displayed by FCM itself.
}

/// Firebase Cloud Messaging implementation of [PushService].
///
/// Tokens are registered through the `registerDevice` callable (and removed by
/// `unregisterDevice`), so the client never writes to `users/{uid}.fcmTokens`
/// directly and the security rules stay tight.
class FirebasePushService implements PushService {
  FirebasePushService({FirebaseMessaging? messaging, FirebaseFunctions? functions})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseMessaging _messaging;
  final FirebaseFunctions _functions;

  final _messages = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<String>.broadcast();

  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _listening = false;

  static PushPermission _map(AuthorizationStatus status) => switch (status) {
        AuthorizationStatus.authorized => PushPermission.granted,
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  /// FlutterFire has no messaging support on Linux or Windows desktop.
  bool get _supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Future<PushPermission> status() async {
    if (!_supported) return PushPermission.unsupported;
    final settings = await _messaging.getNotificationSettings();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<PushPermission> register(String uid) async {
    if (!_supported) return PushPermission.unsupported;

    final settings = await _messaging.requestPermission();
    final permission = _map(settings.authorizationStatus);
    if (permission != PushPermission.granted) return permission;

    final token = await _messaging.getToken(
      vapidKey: Env.vapidKey.isEmpty ? null : Env.vapidKey,
    );
    if (token != null) await _sendToken(token);

    if (!_listening) {
      _listening = true;
      _subscriptions.add(_messaging.onTokenRefresh.listen(_sendToken));
      _subscriptions.add(FirebaseMessaging.onMessage.listen((message) {
        _messages.add(PushMessage.fromData(
          message.data,
          title: message.notification?.title,
          body: message.notification?.body,
        ));
      }));
      _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _opened.add(PushMessage.fromData(message.data).route);
      }));

      // The app may have been started by tapping a notification.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _opened.add(PushMessage.fromData(initial.data).route);
      }
    }
    return PushPermission.granted;
  }

  Future<void> _sendToken(String token) async {
    await _functions.httpsCallable('registerDevice').call<void>({'token': token});
  }

  @override
  Future<void> unregister(String uid) async {
    if (!_supported) return;
    final token = await _messaging.getToken(
      vapidKey: Env.vapidKey.isEmpty ? null : Env.vapidKey,
    );
    if (token != null) {
      await _functions.httpsCallable('unregisterDevice').call<void>({'token': token});
    }
    await _messaging.deleteToken();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _listening = false;
  }

  @override
  Stream<PushMessage> get foregroundMessages => _messages.stream;

  @override
  Stream<String> get openedRoutes => _opened.stream;

  @override
  Future<String?> currentToken() =>
      _messaging.getToken(vapidKey: Env.vapidKey.isEmpty ? null : Env.vapidKey);
}
