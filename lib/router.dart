import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin/admin_screen.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_home_screen.dart';
import 'features/directory/directory_screen.dart';
import 'features/home/home_shell.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/tasks/task_detail_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'providers/providers.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/chat',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final signedIn = auth.value != null;
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin) return '/chat';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatHomeScreen(),
              routes: [
                GoRoute(
                  path: ':channelId',
                  builder: (context, state) =>
                      ChatHomeScreen(channelId: state.pathParameters['channelId']),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
              routes: [
                GoRoute(
                  path: ':taskId',
                  builder: (context, state) =>
                      TaskDetailScreen(taskId: state.pathParameters['taskId']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/agenda', builder: (context, state) => const AgendaScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/members', builder: (context, state) => const DirectoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Rebuilds the router whenever the session changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
