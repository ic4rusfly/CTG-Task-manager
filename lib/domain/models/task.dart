import 'attachment.dart';
import 'enums.dart';

class ChecklistItem {
  const ChecklistItem({required this.id, required this.text, this.done = false});

  final String id;
  final String text;
  final bool done;

  ChecklistItem copyWith({String? text, bool? done}) =>
      ChecklistItem(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
        id: map['id'] as String? ?? '',
        text: map['text'] as String? ?? '',
        done: map['done'] as bool? ?? false,
      );
}

class Task {
  const Task({
    required this.id,
    required this.key,
    required this.title,
    required this.reporterId,
    this.projectId = 'ctg',
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.type = TaskType.task,
    this.assigneeIds = const [],
    this.teamId,
    this.labels = const [],
    this.progress = 0,
    this.dueAt,
    this.estimateHours,
    this.checklist = const [],
    this.attachments = const [],
    this.watcherIds = const [],
    this.groupAssignmentId,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.order = 0,
  });

  final String id;
  final String key;
  final String title;
  final String reporterId;
  final String projectId;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskType type;
  final List<String> assigneeIds;
  final String? teamId;
  final List<String> labels;
  final int progress;
  final DateTime? dueAt;
  final double? estimateHours;
  final List<ChecklistItem> checklist;
  final List<Attachment> attachments;
  final List<String> watcherIds;
  final String? groupAssignmentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final int order;

  bool get isDone => status == TaskStatus.done;

  bool get isOverdue =>
      !isDone && dueAt != null && dueAt!.isBefore(DateTime.now());

  int get checklistDone => checklist.where((c) => c.done).length;

  /// Progress derived from the checklist when one exists, otherwise the
  /// manually set percentage.
  int get effectiveProgress {
    if (isDone) return 100;
    if (checklist.isEmpty) return progress;
    return ((checklistDone / checklist.length) * 100).round();
  }

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    TaskType? type,
    List<String>? assigneeIds,
    String? teamId,
    List<String>? labels,
    int? progress,
    DateTime? dueAt,
    double? estimateHours,
    List<ChecklistItem>? checklist,
    List<Attachment>? attachments,
    List<String>? watcherIds,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? order,
  }) =>
      Task(
        id: id,
        key: key,
        title: title ?? this.title,
        reporterId: reporterId,
        projectId: projectId,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        type: type ?? this.type,
        assigneeIds: assigneeIds ?? this.assigneeIds,
        teamId: teamId ?? this.teamId,
        labels: labels ?? this.labels,
        progress: progress ?? this.progress,
        dueAt: dueAt ?? this.dueAt,
        estimateHours: estimateHours ?? this.estimateHours,
        checklist: checklist ?? this.checklist,
        attachments: attachments ?? this.attachments,
        watcherIds: watcherIds ?? this.watcherIds,
        groupAssignmentId: groupAssignmentId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        order: order ?? this.order,
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'title': title,
        'reporterId': reporterId,
        'projectId': projectId,
        'description': description,
        'status': status.name,
        'priority': priority.name,
        'type': type.name,
        'assigneeIds': assigneeIds,
        'teamId': teamId,
        'labels': labels,
        'progress': progress,
        'dueAt': dueAt?.toIso8601String(),
        'estimateHours': estimateHours,
        'checklist': checklist.map((c) => c.toMap()).toList(),
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'watcherIds': watcherIds,
        'groupAssignmentId': groupAssignmentId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'order': order,
      };

  factory Task.fromMap(String id, Map<String, dynamic> map) => Task(
        id: id,
        key: map['key'] as String? ?? id,
        title: map['title'] as String? ?? '',
        reporterId: map['reporterId'] as String? ?? '',
        projectId: map['projectId'] as String? ?? 'ctg',
        description: map['description'] as String? ?? '',
        status: taskStatusFrom(map['status'] as String?),
        priority: taskPriorityFrom(map['priority'] as String?),
        type: taskTypeFrom(map['type'] as String?),
        assigneeIds: (map['assigneeIds'] as List?)?.cast<String>() ?? const [],
        teamId: map['teamId'] as String?,
        labels: (map['labels'] as List?)?.cast<String>() ?? const [],
        progress: map['progress'] as int? ?? 0,
        dueAt: DateTime.tryParse(map['dueAt'] as String? ?? ''),
        estimateHours: (map['estimateHours'] as num?)?.toDouble(),
        checklist: ((map['checklist'] as List?) ?? const [])
            .map((c) => ChecklistItem.fromMap((c as Map).cast<String, dynamic>()))
            .toList(),
        attachments: ((map['attachments'] as List?) ?? const [])
            .map((a) => Attachment.fromMap((a as Map).cast<String, dynamic>()))
            .toList(),
        watcherIds: (map['watcherIds'] as List?)?.cast<String>() ?? const [],
        groupAssignmentId: map['groupAssignmentId'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
        completedAt: DateTime.tryParse(map['completedAt'] as String? ?? ''),
        order: map['order'] as int? ?? 0,
      );
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TaskComment.fromMap(String id, String taskId, Map<String, dynamic> map) => TaskComment(
        id: id,
        taskId: taskId,
        authorId: map['authorId'] as String? ?? '',
        text: map['text'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
