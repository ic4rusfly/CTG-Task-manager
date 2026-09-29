import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../domain/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

Future<void> showEventEditor(BuildContext context, WidgetRef ref, {DateTime? day}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _EventEditorSheet(day: day ?? DateTime.now()),
    ),
  );
}

class _EventEditorSheet extends ConsumerStatefulWidget {
  const _EventEditorSheet({required this.day});

  final DateTime day;

  @override
  ConsumerState<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<_EventEditorSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  late DateTime _date = widget.day;
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  bool _allDay = false;
  final Set<String> _attendees = {};
  int _color = CtgColors.green.value;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = ref.read(currentUserProvider);
    if (me == null || _title.text.trim().isEmpty) return;
    DateTime at(TimeOfDay time) =>
        DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);
    await ref.read(agendaRepositoryProvider).createEvent(
          AgendaEvent(
            id: '',
            title: _title.text.trim(),
            startAt: _allDay ? DateTime(_date.year, _date.month, _date.day, 0, 0) : at(_start),
            endAt: _allDay ? DateTime(_date.year, _date.month, _date.day, 23, 59) : at(_end),
            createdBy: me.id,
            allDay: _allDay,
            location: _location.text.trim(),
            colorValue: _color,
            attendeeIds: {..._attendees, me.id}.toList(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final users = ref.watch(usersProvider).value ?? const <AppUser>[];
    const palette = [
      CtgColors.green,
      CtgColors.greenSoft,
      CtgColors.chocolate,
      CtgColors.maroon,
      CtgColors.greyDark,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(t.newEvent, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(labelText: t.eventTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: InputDecoration(labelText: t.location),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _allDay,
            title: Text(t.allDay),
            onChanged: (v) => setState(() => _allDay = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(formatDay(_date, locale)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          if (!_allDay)
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.startsAt),
                    subtitle: Text(_start.format(context)),
                    onTap: () async {
                      final picked =
                          await showTimePicker(context: context, initialTime: _start);
                      if (picked != null) setState(() => _start = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.endsAt),
                    subtitle: Text(_end.format(context)),
                    onTap: () async {
                      final picked =
                          await showTimePicker(context: context, initialTime: _end);
                      if (picked != null) setState(() => _end = picked);
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final c in palette)
                GestureDetector(
                  onTap: () => setState(() => _color = c.value),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c.value ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.attendees, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final u in users)
                FilterChip(
                  avatar: UserAvatar(user: u, size: 22),
                  selected: _attendees.contains(u.id),
                  label: Text(u.displayName.split(' ').first),
                  onSelected: (v) => setState(
                      () => v ? _attendees.add(u.id) : _attendees.remove(u.id)),
                ),
            ],
          ),
          const SizedBox(height: 20),
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
                child: FilledButton(onPressed: _submit, child: Text(t.create)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
