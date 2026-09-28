import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final teams = ref.watch(teamsProvider).value ?? const <Team>[];
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    if (me == null) return const SizedBox.shrink();

    final myTasks = tasks.where((task) => task.assigneeIds.contains(me.id)).toList();
    final open = myTasks.where((task) => !task.isDone).length;
    final dueThisWeek = myTasks
        .where((task) =>
            task.dueAt != null &&
            !task.isDone &&
            task.dueAt!.isBefore(DateTime.now().add(const Duration(days: 7))))
        .length;
    final team = teams.where((x) => x.id == me.teamId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.settings,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              UserAvatar(user: me, size: 64, showPresence: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.displayName, style: Theme.of(context).textTheme.titleLarge),
                    Text(me.title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        StatusChip(
                          label: roleLabel(t, me.role),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        if (team.isNotEmpty)
                          StatusChip(
                            label: team.first.name,
                            color: Color(team.first.colorValue),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Stat(label: t.overviewOpenTasks, value: '$open')),
              const SizedBox(width: 10),
              Expanded(child: _Stat(label: t.overviewDueThisWeek, value: '$dueThisWeek')),
            ],
          ),
          const SizedBox(height: 20),
          if (me.bio.isNotEmpty) ...[
            Text(t.bio, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(me.bio),
            const SizedBox(height: 16),
          ],
          Text(t.skills, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final s in me.skills) Chip(label: Text(s)),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alternate_email),
            title: Text(me.email),
          ),
          if (me.phone.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(me.phone),
            ),
          const SizedBox(height: 20),
          Text(t.myTasks, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final task in myTasks.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: ProgressBar(value: task.effectiveProgress, showLabel: true),
              onTap: () => context.go('/tasks/${task.id}'),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(t.signOut),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
