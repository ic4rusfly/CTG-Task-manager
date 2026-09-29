import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'domain/push_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/providers.dart';
import 'router.dart';

class CtgApp extends ConsumerStatefulWidget {
  const CtgApp({super.key});

  @override
  ConsumerState<CtgApp> createState() => _CtgAppState();
}

class _CtgAppState extends ConsumerState<CtgApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _registeredUid;

  /// Registers the device when somebody signs in and drops the token when
  /// they sign out, so a shared phone stops receiving their alerts.
  Future<void> _syncPushRegistration(String? uid) async {
    if (uid == _registeredUid) return;
    final push = ref.read(pushServiceProvider);
    final previous = _registeredUid;
    _registeredUid = uid;
    if (previous != null) await push.unregister(previous);
    if (uid != null) {
      await push.register(uid);
      ref.invalidate(pushPermissionProvider);
    }
  }

  void _showBanner(PushMessage message) {
    final messenger = _messengerKey.currentState;
    final context = _messengerKey.currentContext;
    if (messenger == null || context == null) return;
    final t = AppLocalizations.of(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (message.body.isNotEmpty)
              Text(message.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: SnackBarAction(
          label: t.open,
          onPressed: () => ref.read(routerProvider).go(message.route),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    ref.listen(currentUserProvider, (_, user) => _syncPushRegistration(user?.id));
    ref.listen(pushMessagesProvider, (_, next) {
      final message = next.value;
      if (message != null) _showBanner(message);
    });
    ref.listen(pushOpenedRouteProvider, (_, next) {
      final route = next.value;
      if (route != null && route.isNotEmpty) router.go(route);
    });

    return MaterialApp.router(
      title: 'CTG Hub',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
    );
  }
}
