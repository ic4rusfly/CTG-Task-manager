import 'enums.dart';

class AgendaEvent {
  const AgendaEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.createdBy,
    this.description = '',
    this.allDay = false,
    this.location = '',
    this.meetingUrl,
    this.colorValue = 0xFF2E4A3A,
    this.attendeeIds = const [],
    this.teamIds = const [],
    this.rsvp = const {},
    this.reminderMinutes = const [30],
    this.relatedTaskId,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String createdBy;
  final String description;
  final bool allDay;
  final String location;
  final String? meetingUrl;
  final int colorValue;
  final List<String> attendeeIds;
  final List<String> teamIds;
  final Map<String, Rsvp> rsvp;
  final List<int> reminderMinutes;
  final String? relatedTaskId;

  bool isOnDay(DateTime day) {
    final start = DateTime(startAt.year, startAt.month, startAt.day);
    final end = DateTime(endAt.year, endAt.month, endAt.day);
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  AgendaEvent copyWith({
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? location,
    String? meetingUrl,
    int? colorValue,
    List<String>? attendeeIds,
    List<String>? teamIds,
    Map<String, Rsvp>? rsvp,
  }) =>
      AgendaEvent(
        id: id,
        title: title ?? this.title,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        createdBy: createdBy,
        description: description ?? this.description,
        allDay: allDay ?? this.allDay,
        location: location ?? this.location,
        meetingUrl: meetingUrl ?? this.meetingUrl,
        colorValue: colorValue ?? this.colorValue,
        attendeeIds: attendeeIds ?? this.attendeeIds,
        teamIds: teamIds ?? this.teamIds,
        rsvp: rsvp ?? this.rsvp,
        reminderMinutes: reminderMinutes,
        relatedTaskId: relatedTaskId,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'createdBy': createdBy,
        'description': description,
        'allDay': allDay,
        'location': location,
        'meetingUrl': meetingUrl,
        'colorValue': colorValue,
        'attendeeIds': attendeeIds,
        'teamIds': teamIds,
        'rsvp': rsvp.map((k, v) => MapEntry(k, v.name)),
        'reminderMinutes': reminderMinutes,
        'relatedTaskId': relatedTaskId,
      };

  factory AgendaEvent.fromMap(String id, Map<String, dynamic> map) => AgendaEvent(
        id: id,
        title: map['title'] as String? ?? '',
        startAt: DateTime.tryParse(map['startAt'] as String? ?? '') ?? DateTime.now(),
        endAt: DateTime.tryParse(map['endAt'] as String? ?? '') ?? DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
        description: map['description'] as String? ?? '',
        allDay: map['allDay'] as bool? ?? false,
        location: map['location'] as String? ?? '',
        meetingUrl: map['meetingUrl'] as String?,
        colorValue: map['colorValue'] as int? ?? 0xFF2E4A3A,
        attendeeIds: (map['attendeeIds'] as List?)?.cast<String>() ?? const [],
        teamIds: (map['teamIds'] as List?)?.cast<String>() ?? const [],
        rsvp: ((map['rsvp'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, rsvpFrom(v as String?))),
        reminderMinutes: (map['reminderMinutes'] as List?)?.cast<int>() ?? const [30],
        relatedTaskId: map['relatedTaskId'] as String?,
      );
}
