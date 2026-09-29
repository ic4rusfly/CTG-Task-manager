import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Create / assign a task. Admins and leads can target individuals, a whole
/// team, or a custom group — either as one shared task or one task per person.
Future<void> showTaskEditor(
  BuildContext context,
  WidgetRef ref, {
  List<String> initialAssignees = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _TaskEditorSheet(initialAssignees: initialAssignees),
    ),
  );
}

class _TaskEditorSheet extends ConsumerStatefulWidget {
  const _TaskEditorSheet({this.initialAssignees = const []});

  final List<String> initialAssignees;

  @override
  ConsumerState<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<_TaskEditorSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  late Set<String> _assignees = {...widget.initialAssignees};
  TaskPriority _priority = TaskPriority.medium;
  TaskType _type = TaskType.task;
  TaskStatus _status = TaskStatus.todo;
  DateTime? _dueAt;
  String? _teamId;
  bool _clonePerAssignee = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = ref.read(currentUserProvider);
    if (me == null || _title.text.trim().isEmpty || _assignees.isEmpty) return;
    final created = await ref.read(taskRepositoryProvider).assignToGroup(
          template: Task(
            id: '',
            key: '',
            title: _title.text.trim(),
            description: _description.text.trim(),
            reporterId: me.id,
            status: _status,
            priority: _priority,
            type: _type,
            teamId: _teamId,
            dueAt: _dueAt,
            createdAt: DateTime.now(),
          ),
          assigneeIds: _assignees.toList(),
          clonePerAssignee: _clonePerAssignee,
        );
    if (!mounted) return;
    final t = tr(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.tasksCreated(created.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final users = ref.watch(usersProvider).value ?? const <AppUser>[];
    final teams = ref.watch(teamsProvider).value ?? const <Team>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(t.newTask, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(labelText: t.taskTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: t.description),
          ),
          const SizedBox(height: 16),
          Text(t.priority, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final p in TaskPriority.values)
                ChoiceChip(
                  selected: _priority == p,
                  label: Text(priorityLabel(t, p)),
                  onSelected: (_) => setState(() => _priority = p),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.type, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final ty in TaskType.values)
                ChoiceChip(
                  selected: _type == ty,
                  label: Text(typeLabel(t, ty)),
                  onSelected: (_) => setState(() => _type = ty),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.status, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final s in [TaskStatus.backlog, TaskStatus.todo, TaskStatus.inProgress])
                ChoiceChip(
                  selected: _status == s,
                  label: Text(statusLabel(t, s)),
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(t.dueDate),
            subtitle: Text(_dueAt == null ? '—' : formatDay(_dueAt!, locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueAt ?? now.add(const Duration(days: 3)),
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _dueAt = picked);
            },
          ),
          const Divider(),
          Text(t.selectTeam, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final team in teams)
                ChoiceChip(
                  selected: _teamId == team.id,
                  label: Text(team.name),
                  onSelected: (v) => setState(() {
                    _teamId = v ? team.id : null;
                    if (v) _assignees.addAll(team.memberIds);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.selectPeople, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final u in users)
                FilterChip(
                  avatar: UserAvatar(user: u, size: 22),
                  selected: _assignees.contains(u.id),
                  label: Text(u.displayName.split(' ').first),
                  onSelected: (v) => setState(() {
                    v ? _assignees.add(u.id) : _assignees.remove(u.id);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_assignees.length > 1) ...[
            Text(t.assignMode, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(t.sharedTask)),
                ButtonSegment(value: true, label: Text(t.oneTaskEach)),
              ],
              selected: {_clonePerAssignee},
              onSelectionChanged: (s) => setState(() => _clonePerAssignee = s.first),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _title.text.trim().isEmpty && _assignees.isEmpty ? null : _submit,
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(t.assign),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
