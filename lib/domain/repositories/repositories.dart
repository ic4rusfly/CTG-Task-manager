import '../models/models.dart';

/// Authentication + "who am I" concerns.
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
}

abstract class UserRepository {
  Stream<List<AppUser>> watchUsers();
  Stream<List<Team>> watchTeams();
  Future<AppUser?> getUser(String id);
  Future<void> updateProfile(AppUser user);
  Future<void> setLocale(String uid, String locale);
  Future<void> setRole(String uid, UserRole role);
  Future<void> setActive(String uid, bool active);
}

abstract class ChatRepository {
  /// Channels and DMs the user belongs to, most recent activity first.
  Stream<List<Channel>> watchChannels(String uid);
  Stream<List<Message>> watchMessages(String channelId, {int limit = 100});
  Future<void> sendMessage(Message message);
  Future<void> toggleReaction(String channelId, String messageId, String emoji, String uid);
  Future<void> deleteMessage(String channelId, String messageId);
  Future<void> markRead(String channelId, String uid);
  Future<Channel> createChannel({
    required String name,
    required ChannelType type,
    required List<String> memberIds,
    String topic = '',
    String? createdBy,
  });
  /// Returns the existing 1-to-1 channel with [peerId] or creates one.
  Future<Channel> openDm(String uid, String peerId);
}

abstract class TaskRepository {
  Stream<List<Task>> watchTasks();
  Stream<List<TaskComment>> watchComments(String taskId);
  Future<Task> createTask(Task task);
  /// Assign one task to many people, or clone it once per person.
  Future<List<Task>> assignToGroup({
    required Task template,
    required List<String> assigneeIds,
    bool clonePerAssignee = false,
  });
  Future<void> updateTask(Task task);
  Future<void> setStatus(String taskId, TaskStatus status);
  Future<void> setProgress(String taskId, int progress);
  Future<void> toggleChecklistItem(String taskId, String itemId);
  Future<void> addComment(TaskComment comment);
  Future<void> deleteTask(String taskId);
}

abstract class AgendaRepository {
  Stream<List<AgendaEvent>> watchEvents();
  Future<AgendaEvent> createEvent(AgendaEvent event);
  Future<void> updateEvent(AgendaEvent event);
  Future<void> setRsvp(String eventId, String uid, Rsvp rsvp);
  Future<void> deleteEvent(String eventId);
}

abstract class NotificationRepository {
  Stream<List<AppNotification>> watch(String uid);
  Future<void> add(AppNotification notification);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
}
