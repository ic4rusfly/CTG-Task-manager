import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static IconData iconFor(NotificationKind kind) => switch (kind) {
        NotificationKind.mention => Icons.alternate_email,
        NotificationKind.message => Icons.forum_outlined,
        NotificationKind.taskAssigned => Icons.assignment_ind_outlined,
        NotificationKind.taskStatus => Icons.sync_alt,
        NotificationKind.dueSoon => Icons.schedule_outlined,
        NotificationKind.eventInvite => Icons.event_available_outlined,
      };

  static Color colorFor(NotificationKind kind) => switch (kind) {
        NotificationKind.dueSoon => CtgColors.maroon,
        NotificationKind.taskAssigned => CtgColors.green,
        NotificationKind.mention => CtgColors.chocolate,
        _ => CtgColors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final me = ref.watch(currentUserProvider);
    final items = ref.watch(notificationsProvider).value ?? const <AppNotification>[];
    final unread = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notificationCenter),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: me == null
                  ? null
                  : () => ref.read(notificationRepositoryProvider).markAllRead(me.id),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(t.markAllRead),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Text(
                t.unreadCount(unread),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
      ),
      body: items.isEmpty
          ? EmptyState(icon: Icons.notifications_none, message: t.noNotifications)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                final color = colorFor(n.kind);
                return SoftCard(
                  borderColor: n.read ? null : color.withOpacity(.55),
                  onTap: () {
                    if (me != null) {
                      ref.read(notificationRepositoryProvider).markRead(me.id, n.id);
                    }
                    context.go(n.route);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withOpacity(.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(iconFor(n.kind), size: 17, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                              ),
                            ),
                            if (n.body.isNotEmpty)
                              Text(
                                n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRelative(n.createdAt, locale, t),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
