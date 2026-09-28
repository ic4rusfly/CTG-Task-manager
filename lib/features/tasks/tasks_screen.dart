import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'task_card.dart';
import 'task_editor.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _boardView = true;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final me = ref.watch(currentUserProvider);
    final filter = ref.watch(taskFilterProvider);
    final tasks = ref.watch(filteredTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.tasks),
        actions: [
          IconButton(
            tooltip: _boardView ? t.list : t.board,
            icon: Icon(_boardView ? Icons.view_list_outlined : Icons.view_kanban_outlined),
            onPressed: () => setState(() => _boardView = !_boardView),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: t.searchTasks,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(taskFilterProvider.notifier).state =
                      filter.copyWith(query: v),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: filter.onlyMine,
                          label: Text(t.myTasks),
                          onSelected: (v) => ref.read(taskFilterProvider.notifier).state =
                              filter.copyWith(onlyMine: v),
                        ),
                        const SizedBox(width: 8),
                        for (final team in ref.watch(teamsProvider).value ?? const <Team>[])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: FilterChip(
                              selected: filter.teamId == team.id,
                              label: Text(team.name),
                              onSelected: (v) => ref.read(taskFilterProvider.notifier).state =
                                  v ? filter.copyWith(teamId: team.id) : filter.copyWith(clearTeam: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: (me?.canAssign ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => showTaskEditor(context, ref),
              icon: const Icon(Icons.add),
              label: Text(t.newTask),
            )
          : null,
      body: tasks.isEmpty
          ? EmptyState(icon: Icons.task_alt, message: t.noTasks)
          : _boardView
              ? _BoardView(tasks: tasks)
              : _ListView(tasks: tasks),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => TaskCard(
        task: tasks[i],
        onTap: () => context.go('/tasks/${tasks[i].id}'),
      ),
    );
  }
}

class _BoardView extends ConsumerWidget {
  const _BoardView({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final columnWidth = isCompact(context) ? 280.0 : 300.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final status in kBoardStatuses)
            Container(
              width: columnWidth,
              margin: const EdgeInsetsDirectional.only(end: 12),
              child: DragTarget<Task>(
                onWillAcceptWithDetails: (d) => d.data.status != status,
                onAcceptWithDetails: (d) =>
                    ref.read(taskRepositoryProvider).setStatus(d.data.id, status),
                builder: (context, candidate, rejected) {
                  final items = tasks.where((task) => task.status == status).toList();
                  return Container(
                    decoration: BoxDecoration(
                      color: candidate.isNotEmpty
                          ? CtgColors.statusColors[status]!.withOpacity(.10)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: CtgColors.statusColors[status],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(statusLabel(t, status),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Text('${items.length}',
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final task in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LongPressDraggable<Task>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: columnWidth - 20,
                                  child: Opacity(
                                    opacity: .9,
                                    child: TaskCard(task: task, compact: true),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: .3,
                                child: TaskCard(task: task, compact: true),
                              ),
                              child: TaskCard(
                                task: task,
                                onTap: () => context.go('/tasks/${task.id}'),
                              ),
                            ),
                          ),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              t.noTasks,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
