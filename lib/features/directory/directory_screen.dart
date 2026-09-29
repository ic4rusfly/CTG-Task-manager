import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../tasks/task_editor.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final teams = ref.watch(teamsProvider).value ?? const <Team>[];
    final users = (ref.watch(usersProvider).value ?? const <AppUser>[]).where((u) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) ||
          u.title.toLowerCase().contains(q) ||
          u.skills.any((s) => s.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.members),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: t.searchMembers,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          for (final team in teams)
            if (users.any((u) => u.teamId == team.id)) ...[
              SectionHeader('${team.name} · ${t.membersCount(team.memberIds.length)}'),
              for (final u in users.where((u) => u.teamId == team.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberCard(user: u, me: me),
                ),
            ],
          if (users.any((u) => u.teamId == null)) ...[
            SectionHeader(t.members),
            for (final u in users.where((u) => u.teamId == null))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberCard(user: u, me: me),
              ),
          ],
        ],
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.user, required this.me});

  final AppUser user;
  final AppUser? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    return SoftCard(
      child: Row(
        children: [
          UserAvatar(user: user, size: 46, showPresence: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    if (user.role != UserRole.member)
                      StatusChip(
                        label: roleLabel(t, user.role),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                Text(user.title, style: Theme.of(context).textTheme.bodySmall),
                if (user.skills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final s in user.skills)
                        StatusChip(label: s, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (me != null && me!.id != user.id)
            IconButton(
              tooltip: t.message,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () async {
                final channel =
                    await ref.read(chatRepositoryProvider).openDm(me!.id, user.id);
                if (context.mounted) context.go('/chat/${channel.id}');
              },
            ),
          if (me?.canAssign ?? false)
            IconButton(
              tooltip: t.assignTask,
              icon: const Icon(Icons.add_task),
              onPressed: () => showTaskEditor(context, ref, initialAssignees: [user.id]),
            ),
        ],
      ),
    );
  }
}
