import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/mock_db.dart';
import '../data/mock/mock_repositories.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';

/// ---------------------------------------------------------------------------
/// Data layer wiring.
///
/// Today every repository resolves to its in-memory mock implementation, which
/// is what lets the whole app run with zero backend. In phase 1 the Firebase
/// implementations are dropped in here — nothing else in the app changes.
/// ---------------------------------------------------------------------------
final mockDbProvider = Provider<MockDb>((ref) => MockDb());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(mockDbProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => MockUserRepository(
    ref.watch(mockDbProvider),
    ref.watch(authRepositoryProvider) as MockAuthRepository,
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => MockNotificationRepository(ref.watch(mockDbProvider)),
);

/// Composes in-app notifications in mock mode; in Firebase mode the Cloud
/// Functions do this server-side, so the client notifier is skipped.
final mockNotifierProvider = Provider<MockNotifier?>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  if (repo is! MockNotificationRepository) return null;
  return MockNotifier(ref.watch(mockDbProvider), repo);
});

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => MockChatRepository(ref.watch(mockDbProvider), ref.watch(mockNotifierProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => MockTaskRepository(ref.watch(mockDbProvider), ref.watch(mockNotifierProvider)),
);

final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => MockAgendaRepository(ref.watch(mockDbProvider)),
);

/// Attachment storage: in-memory by default, Cloud Storage with
/// `--dart-define=BACKEND=firebase`.
final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MockMediaRepository(ref.watch(mockDbProvider)),
);

/// ---------------------------------------------------------------------------
/// Session
/// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).value,
);

/// Locale follows the signed-in member's preference, with an override for
/// users who change it before signing in.
final localeOverrideProvider = StateProvider<Locale?>((ref) => null);

final localeProvider = Provider<Locale>((ref) {
  final override = ref.watch(localeOverrideProvider);
  if (override != null) return override;
  final user = ref.watch(currentUserProvider);
  return Locale(user?.locale ?? 'en');
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// ---------------------------------------------------------------------------
/// Shared collections
/// ---------------------------------------------------------------------------
final usersProvider = StreamProvider<List<AppUser>>(
  (ref) => ref.watch(userRepositoryProvider).watchUsers(),
);

final teamsProvider = StreamProvider<List<Team>>(
  (ref) => ref.watch(userRepositoryProvider).watchTeams(),
);

/// Users indexed by id — the lookup every list tile needs.
final usersByIdProvider = Provider<Map<String, AppUser>>((ref) {
  final users = ref.watch(usersProvider).value ?? const <AppUser>[];
  return {for (final u in users) u.id: u};
});

final channelsProvider = StreamProvider<List<Channel>>((ref) {
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchChannels(uid);
});

final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, channelId) {
  return ref.watch(chatRepositoryProvider).watchMessages(channelId);
});

/// Replies under one root message.
final threadProvider =
    StreamProvider.family<List<Message>, ({String channelId, String rootId})>((ref, key) {
  return ref.watch(chatRepositoryProvider).watchThread(key.channelId, key.rootId);
});

/// One message by id, from the already-streamed channel.
final messageProvider =
    Provider.family<Message?, ({String channelId, String messageId})>((ref, key) {
  final messages = ref.watch(messagesProvider(key.channelId)).value ?? const <Message>[];
  for (final m in messages) {
    if (m.id == key.messageId) return m;
  }
  return null;
});

final tasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchTasks(),
);

final taskProvider = Provider.family<Task?, String>((ref, id) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  for (final t in tasks) {
    if (t.id == id) return t;
  }
  return null;
});

final taskCommentsProvider =
    StreamProvider.family<List<TaskComment>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).watchComments(taskId);
});

final eventsProvider = StreamProvider<List<AgendaEvent>>(
  (ref) => ref.watch(agendaRepositoryProvider).watchEvents(),
);

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watch(uid);
});

final unreadNotificationsProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).value ?? const <AppNotification>[];
  return items.where((n) => !n.read).length;
});

/// Full-text search across every message the signed-in member can see.
class MessageHit {
  const MessageHit(this.message, this.channel);

  final Message message;
  final Channel channel;
}

final messageSearchQueryProvider = StateProvider<String>((ref) => '');

final messageSearchProvider = Provider<List<MessageHit>>((ref) {
  final query = ref.watch(messageSearchQueryProvider).trim().toLowerCase();
  if (query.length < 2) return const [];
  final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
  final hits = <MessageHit>[];
  for (final channel in channels) {
    final messages = ref.watch(messagesProvider(channel.id)).value ?? const <Message>[];
    for (final message in messages) {
      if (message.deleted) continue;
      final haystack =
          '${message.text} ${message.attachments.map((a) => a.name).join(' ')}'.toLowerCase();
      if (haystack.contains(query)) hits.add(MessageHit(message, channel));
    }
  }
  hits.sort((a, b) => b.message.sentAt.compareTo(a.message.sentAt));
  return hits;
});

/// ---------------------------------------------------------------------------
/// Task filtering (board + list share this state)
/// ---------------------------------------------------------------------------
class TaskFilter {
  const TaskFilter({this.onlyMine = false, this.query = '', this.teamId});

  final bool onlyMine;
  final String query;
  final String? teamId;

  TaskFilter copyWith({bool? onlyMine, String? query, String? teamId, bool clearTeam = false}) =>
      TaskFilter(
        onlyMine: onlyMine ?? this.onlyMine,
        query: query ?? this.query,
        teamId: clearTeam ? null : (teamId ?? this.teamId),
      );
}

final taskFilterProvider = StateProvider<TaskFilter>((ref) => const TaskFilter());

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final uid = ref.watch(currentUserProvider)?.id;
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final q = filter.query.trim().toLowerCase();
  return tasks.where((t) {
    if (filter.onlyMine && uid != null && !t.assigneeIds.contains(uid)) return false;
    if (filter.teamId != null && t.teamId != filter.teamId) return false;
    if (q.isNotEmpty &&
        !t.title.toLowerCase().contains(q) &&
        !t.key.toLowerCase().contains(q) &&
        !t.labels.any((l) => l.toLowerCase().contains(q))) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      return (a.dueAt ?? DateTime(2100)).compareTo(b.dueAt ?? DateTime(2100));
    });
});

/// Unread counter per channel, derived from lastReadAt.
final unreadCountProvider = Provider.family<int, String>((ref, channelId) {
  final uid = ref.watch(currentUserProvider)?.id;
  final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
  final messages = ref.watch(messagesProvider(channelId)).value ?? const <Message>[];
  if (uid == null) return 0;
  Channel? channel;
  for (final c in channels) {
    if (c.id == channelId) channel = c;
  }
  final since = channel?.lastReadAt[uid];
  return messages
      .where((m) => m.senderId != uid && (since == null || m.sentAt.isAfter(since)))
      .length;
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final visibleMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
