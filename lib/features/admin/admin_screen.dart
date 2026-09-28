import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/labels.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../tasks/task_editor.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final users = ref.watch(usersProvider).value ?? const <AppUser>[];
    final teams = ref.watch(teamsProvider).value ?? const <Team>[];
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];

    if (!(me?.canAssign ?? false)) {
      return Scaffold(
        appBar: AppBar(title: Text(t.admin)),
        body: EmptyState(icon: Icons.lock_outline, message: t.adminOnly),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.admin)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditor(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: Text(t.assignToGroup),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: t.members,
                    value: '${users.where((u) => u.active).length}',
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: t.overviewOpenTasks,
                    value: '${tasks.where((task) => !task.isDone).length}',
                    icon: Icons.task_alt,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: t.overdue,
                    value: '${tasks.where((task) => task.isOverdue).length}',
                    icon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(t.team),
          for (final team in teams)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(team.colorValue).withOpacity(.2),
                child: Icon(Icons.groups_outlined, color: Color(team.colorValue)),
              ),
              title: Text(team.name),
              subtitle: Text(t.membersCount(team.memberIds.length)),
              trailing: TextButton(
                onPressed: () =>
                    showTaskEditor(context, ref, initialAssignees: team.memberIds),
                child: Text(t.assign),
              ),
            ),
          SectionHeader(t.manageMembers),
          for (final u in users)
            ListTile(
              leading: UserAvatar(user: u, size: 40, showPresence: true),
              title: Text(u.displayName),
              subtitle: Text('${u.title} · ${roleLabel(t, u.role)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (me!.isAdmin)
                    PopupMenuButton<UserRole>(
                      tooltip: t.role,
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onSelected: (role) =>
                          ref.read(userRepositoryProvider).setRole(u.id, role),
                      itemBuilder: (context) => [
                        for (final r in UserRole.values)
                          PopupMenuItem(value: r, child: Text(roleLabel(t, r))),
                      ],
                    ),
                  if (me.isAdmin)
                    Switch(
                      value: u.active,
                      onChanged: (v) =>
                          ref.read(userRepositoryProvider).setActive(u.id, v),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
