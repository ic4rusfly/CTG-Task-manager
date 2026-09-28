import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task, this.onTap, this.compact = false});

  final Task task;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final usersById = ref.watch(usersByIdProvider);
    final assignees = task.assigneeIds
        .map((id) => usersById[id])
        .whereType<AppUser>()
        .toList();

    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                switch (task.type) {
                  TaskType.bug => Icons.bug_report_outlined,
                  TaskType.feature => Icons.auto_awesome_outlined,
                  TaskType.task => Icons.check_box_outlined,
                },
                size: 15,
                color: CtgColors.priorityColors[task.priority],
              ),
              const SizedBox(width: 6),
              Text(task.key,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              const Spacer(),
              StatusChip(
                label: priorityLabel(t, task.priority),
                color: CtgColors.priorityColors[task.priority]!,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (task.labels.isNotEmpty && !compact) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final l in task.labels)
                  StatusChip(label: l, color: Theme.of(context).colorScheme.outline),
              ],
            ),
          ],
          const SizedBox(height: 10),
          ProgressBar(value: task.effectiveProgress, showLabel: true),
          const SizedBox(height: 10),
          Row(
            children: [
              AvatarStack(users: assignees, size: 24),
              const Spacer(),
              if (task.checklist.isNotEmpty) ...[
                Icon(Icons.checklist, size: 14, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 3),
                Text('${task.checklistDone}/${task.checklist.length}',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(width: 10),
              ],
              if (task.dueAt != null)
                StatusChip(
                  icon: Icons.event_outlined,
                  label: formatShortDay(task.dueAt!, locale),
                  color: task.isOverdue ? CtgColors.maroon : Theme.of(context).colorScheme.outline,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
