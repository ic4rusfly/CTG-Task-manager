import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../core/labels.dart';
import '../../widgets/common.dart';
import 'event_editor.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final me = ref.watch(currentUserProvider);
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final events = ref.watch(eventsProvider).value ?? const <AgendaEvent>[];
    final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final dayEvents = events.where((e) => e.isOnDay(selected)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final dayTasks = tasks
        .where((task) => task.dueAt != null && DateUtils.isSameDay(task.dueAt!, selected))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(t.agenda)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEventEditor(context, ref, day: selected),
        icon: const Icon(Icons.add),
        label: Text(t.newEvent),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          _MonthHeader(month: month, locale: locale),
          _MonthGrid(
            month: month,
            selected: selected,
            events: events,
            onSelect: (day) => ref.read(selectedDayProvider.notifier).state = day,
          ),
          const SizedBox(height: 8),
          SectionHeader(formatDay(selected, locale)),
          if (dayEvents.isEmpty && dayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(icon: Icons.event_busy_outlined, message: t.noEvents),
            ),
          for (final e in dayEvents)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _EventTile(event: e, me: me),
            ),
          for (final task in dayTasks)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 10),
              child: SoftCard(
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${task.key} · ${task.title}')),
                    StatusChip(label: t.dueDate, color: Theme.of(context).colorScheme.outline),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.month, required this.locale});

  final DateTime month;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Text(
            DateFormat.yMMMM(locale).format(month),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(visibleMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          IconButton(
            icon: const Icon(Icons.today_outlined),
            onPressed: () {
              final now = DateTime.now();
              ref.read(visibleMonthProvider.notifier).state = DateTime(now.year, now.month);
              ref.read(selectedDayProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(visibleMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final List<AgendaEvent> events;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (first.weekday - 1) % 7; // Monday-first grid
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      for (var d = 1; d <= daysInMonth; d++) DateTime(month.year, month.month, d),
    ];
    final weekdayLabels = List.generate(7, (i) {
      final day = DateTime(2024, 1, 1).add(Duration(days: i)); // Monday
      return DateFormat.E(locale).format(day);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: cells.length,
            itemBuilder: (context, i) {
              final day = cells[i];
              if (day == null) return const SizedBox.shrink();
              final isSelected = DateUtils.isSameDay(day, selected);
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final dots = events.where((e) => e.isOnDay(day)).take(3).toList();
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelect(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                            ? Theme.of(context).colorScheme.primary.withOpacity(.10)
                            : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final e in dots)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Color(e.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event, required this.me});

  final AgendaEvent event;
  final AppUser? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final usersById = ref.watch(usersByIdProvider);
    final myRsvp = me == null ? null : event.rsvp[me!.id];

    return SoftCard(
      borderColor: Color(event.colorValue).withOpacity(.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(event.colorValue),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      event.allDay
                          ? t.allDay
                          : '${formatTime(event.startAt, locale)} – ${formatTime(event.endAt, locale)}'
                              '${event.location.isEmpty ? '' : ' · ${event.location}'}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              AvatarStack(
                users: event.attendeeIds
                    .map((id) => usersById[id])
                    .whereType<AppUser>()
                    .toList(),
                size: 22,
              ),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(event.description, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final r in Rsvp.values)
                ChoiceChip(
                  selected: myRsvp == r,
                  label: Text(rsvpLabel(t, r)),
                  onSelected: me == null
                      ? null
                      : (_) => ref
                          .read(agendaRepositoryProvider)
                          .setRsvp(event.id, me!.id, r),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
