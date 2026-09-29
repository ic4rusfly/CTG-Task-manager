/// Shared enumerations for CTG Hub.
enum UserRole { member, lead, admin }

enum TaskStatus { backlog, todo, inProgress, review, done, blocked }

enum TaskPriority { low, medium, high, urgent }

enum TaskType { task, bug, feature }

enum ChannelType { general, public, private, dm, groupDm }

enum MessageType { text, image, file, audio, link, taskRef, system }

enum Rsvp { going, maybe, no }

T _enumFrom<T extends Enum>(List<T> values, String? name, T fallback) {
  return values.firstWhere(
    (v) => v.name == name,
    orElse: () => fallback,
  );
}

UserRole userRoleFrom(String? v) => _enumFrom(UserRole.values, v, UserRole.member);
TaskStatus taskStatusFrom(String? v) => _enumFrom(TaskStatus.values, v, TaskStatus.todo);
TaskPriority taskPriorityFrom(String? v) => _enumFrom(TaskPriority.values, v, TaskPriority.medium);
TaskType taskTypeFrom(String? v) => _enumFrom(TaskType.values, v, TaskType.task);
ChannelType channelTypeFrom(String? v) => _enumFrom(ChannelType.values, v, ChannelType.public);
MessageType messageTypeFrom(String? v) => _enumFrom(MessageType.values, v, MessageType.text);
Rsvp rsvpFrom(String? v) => _enumFrom(Rsvp.values, v, Rsvp.maybe);

/// Board column order used by the kanban view.
const kBoardStatuses = <TaskStatus>[
  TaskStatus.todo,
  TaskStatus.inProgress,
  TaskStatus.review,
  TaskStatus.done,
];
