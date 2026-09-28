import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final task = ref.watch(taskProvider(widget.taskId));
    final me = ref.watch(currentUserProvider);
    final usersById = ref.watch(usersByIdProvider);
    final comments = ref.watch(taskCommentsProvider(widget.taskId)).value ?? const <TaskComment>[];

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off, message: t.noTasks),
      );
    }

    final repo = ref.read(taskRepositoryProvider);
    final canEdit = (me?.canAssign ?? false) || task.assigneeIds.contains(me?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(task.key),
        actions: [
          if (me?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: t.delete,
              onPressed: () async {
                await repo.deleteTask(task.id);
                if (context.mounted) Navigator.of(context).maybePop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: statusLabel(t, task.status),
                color: CtgColors.statusColors[task.status]!,
                dense: false,
              ),
              StatusChip(
                label: priorityLabel(t, task.priority),
                color: CtgColors.priorityColors[task.priority]!,
                dense: false,
              ),
              StatusChip(
                label: typeLabel(t, task.type),
                color: Theme.of(context).colorScheme.outline,
                dense: false,
              ),
              if (task.dueAt != null)
                StatusChip(
                  icon: Icons.event_outlined,
                  label: formatDay(task.dueAt!, locale),
                  color: task.isOverdue ? CtgColors.maroon : Theme.of(context).colorScheme.outline,
                  dense: false,
                ),
              if (task.groupAssignmentId != null)
                StatusChip(
                  icon: Icons.groups_outlined,
                  label: t.assignToGroup,
                  color: CtgColors.chocolate,
                  dense: false,
                ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(task.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 22),
          Text('${t.progress} · ${task.effectiveProgress}%',
              style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: task.effectiveProgress.toDouble(),
            max: 100,
            divisions: 20,
            label: '${task.effectiveProgress}%',
            onChanged: canEdit && task.checklist.isEmpty
                ? (v) => repo.setProgress(task.id, v.round())
                : null,
          ),
          if (task.checklist.isNotEmpty)
            Text(
              '${t.checklist} — ${task.checklistDone}/${task.checklist.length}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          const SizedBox(height: 10),
          Text(t.status, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in TaskStatus.values)
                ChoiceChip(
                  selected: task.status == s,
                  label: Text(statusLabel(t, s)),
                  onSelected: canEdit ? (_) => repo.setStatus(task.id, s) : null,
                ),
            ],
          ),
          const SizedBox(height: 22),
          _PeopleRow(
            label: t.assignees,
            users: task.assigneeIds.map((id) => usersById[id]).whereType<AppUser>().toList(),
          ),
          const SizedBox(height: 10),
          _PeopleRow(
            label: t.reporter,
            users: [usersById[task.reporterId]].whereType<AppUser>().toList(),
          ),
          if (task.checklist.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(t.checklist, style: Theme.of(context).textTheme.titleMedium),
            for (final item in task.checklist)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: item.done,
                title: Text(
                  item.text,
                  style: TextStyle(
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                onChanged: canEdit ? (_) => repo.toggleChecklistItem(task.id, item.id) : null,
              ),
          ],
          const SizedBox(height: 22),
          Text(t.comments, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (comments.isEmpty)
            Text('—', style: Theme.of(context).textTheme.bodySmall)
          else
            for (final c in comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(user: usersById[c.authorId], size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(usersById[c.authorId]?.displayName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text(formatRelative(c.createdAt, locale, t),
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          Text(c.text),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _comment,
                  decoration: InputDecoration(hintText: t.addComment, isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_comment.text.trim().isEmpty || me == null) return;
                  repo.addComment(TaskComment(
                    id: '',
                    taskId: task.id,
                    authorId: me.id,
                    text: _comment.text.trim(),
                    createdAt: DateTime.now(),
                  ));
                  _comment.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeopleRow extends StatelessWidget {
  const _PeopleRow({required this.label, required this.users});

  final String label;
  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final u in users)
                Chip(
                  avatar: UserAvatar(user: u, size: 20),
                  label: Text(u.displayName),
                  visualDensity: VisualDensity.compact,
                ),
              if (users.isEmpty) const Text('—'),
            ],
          ),
        ),
      ],
    );
  }
}
