import 'dart:async';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import 'mock_db.dart';

int _seq = 0;
String _id(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch}${_seq++}';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._db);

  final MockDb _db;
  final _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _ctrl.stream;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final user = _db.users.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw Exception('unknown-user'),
    );
    if (!user.active) throw Exception('user-disabled');
    _current = user;
    _ctrl.add(user);
    return user;
  }

  /// Demo helper: sign in as any seeded member without a password.
  Future<AppUser> signInAs(String uid) async {
    final user = _db.users.firstWhere((u) => u.id == uid);
    _current = user;
    _ctrl.add(user);
    return user;
  }

  void refreshCurrent() {
    if (_current == null) return;
    _current = _db.users.firstWhere((u) => u.id == _current!.id, orElse: () => _current!);
    _ctrl.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _ctrl.add(null);
  }
}

class MockUserRepository implements UserRepository {
  MockUserRepository(this._db, this._auth);

  final MockDb _db;
  final MockAuthRepository _auth;

  @override
  Stream<List<AppUser>> watchUsers() => _db.watchUsers();

  @override
  Stream<List<Team>> watchTeams() => _db.watchTeams();

  @override
  Future<AppUser?> getUser(String id) async =>
      _db.users.where((u) => u.id == id).firstOrNull;

  void _replace(AppUser user) {
    final i = _db.users.indexWhere((u) => u.id == user.id);
    if (i != -1) _db.users[i] = user;
    _db.pingUsers();
    _auth.refreshCurrent();
  }

  @override
  Future<void> updateProfile(AppUser user) async => _replace(user);

  @override
  Future<void> setLocale(String uid, String locale) async {
    final u = _db.users.firstWhere((u) => u.id == uid);
    _replace(u.copyWith(locale: locale));
  }

  @override
  Future<void> setRole(String uid, UserRole role) async {
    final u = _db.users.firstWhere((u) => u.id == uid);
    _replace(u.copyWith(role: role));
  }

  @override
  Future<void> setActive(String uid, bool active) async {
    final u = _db.users.firstWhere((u) => u.id == uid);
    _replace(u.copyWith(active: active));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class MockChatRepository implements ChatRepository {
  MockChatRepository(this._db);

  final MockDb _db;

  @override
  Stream<List<Channel>> watchChannels(String uid) => _db.watchChannels().map((all) {
        final mine = all.where((c) => c.memberIds.contains(uid)).toList()
          ..sort((a, b) => (b.lastMessageAt ?? DateTime(1970))
              .compareTo(a.lastMessageAt ?? DateTime(1970)));
        return mine;
      });

  @override
  Stream<List<Message>> watchMessages(String channelId, {int limit = 100}) =>
      _db.watchMessages(channelId).map((all) {
        final sorted = [...all]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
        return sorted.length <= limit ? sorted : sorted.sublist(sorted.length - limit);
      });

  @override
  Future<void> sendMessage(Message message) async {
    final msg = message.id.isEmpty
        ? Message(
            id: _id('m'),
            channelId: message.channelId,
            senderId: message.senderId,
            sentAt: message.sentAt,
            type: message.type,
            text: message.text,
            attachments: message.attachments,
            taskId: message.taskId,
            linkUrl: message.linkUrl,
            replyToId: message.replyToId,
            mentions: message.mentions,
          )
        : message;
    _db.messages.putIfAbsent(msg.channelId, () => []).add(msg);
    final i = _db.channels.indexWhere((c) => c.id == msg.channelId);
    if (i != -1) {
      _db.channels[i] = _db.channels[i].copyWith(
        lastMessageText: msg.text.isEmpty ? msg.attachments.firstOrNull?.name ?? '' : msg.text,
        lastMessageAt: msg.sentAt,
        lastMessageSenderId: msg.senderId,
      );
    }
    _db.pingMessages(msg.channelId);
    _db.pingChannels();
  }

  @override
  Future<void> toggleReaction(
      String channelId, String messageId, String emoji, String uid) async {
    final list = _db.messages[channelId];
    if (list == null) return;
    final i = list.indexWhere((m) => m.id == messageId);
    if (i == -1) return;
    final current = {
      for (final e in list[i].reactions.entries) e.key: [...e.value],
    };
    final users = current.putIfAbsent(emoji, () => <String>[]);
    users.contains(uid) ? users.remove(uid) : users.add(uid);
    if (users.isEmpty) current.remove(emoji);
    list[i] = list[i].copyWith(reactions: current);
    _db.pingMessages(channelId);
  }

  @override
  Future<void> deleteMessage(String channelId, String messageId) async {
    final list = _db.messages[channelId];
    if (list == null) return;
    final i = list.indexWhere((m) => m.id == messageId);
    if (i == -1) return;
    list[i] = list[i].copyWith(deleted: true, text: '');
    _db.pingMessages(channelId);
  }

  @override
  Future<void> markRead(String channelId, String uid) async {
    final i = _db.channels.indexWhere((c) => c.id == channelId);
    if (i == -1) return;
    final map = Map<String, DateTime>.from(_db.channels[i].lastReadAt)
      ..[uid] = DateTime.now();
    _db.channels[i] = _db.channels[i].copyWith(lastReadAt: map);
    _db.pingChannels();
  }

  @override
  Future<Channel> createChannel({
    required String name,
    required ChannelType type,
    required List<String> memberIds,
    String topic = '',
    String? createdBy,
  }) async {
    final channel = Channel(
      id: _id('c'),
      name: name,
      type: type,
      topic: topic,
      memberIds: memberIds,
      createdBy: createdBy,
      lastMessageAt: DateTime.now(),
    );
    _db.channels.add(channel);
    _db.pingChannels();
    return channel;
  }

  @override
  Future<Channel> openDm(String uid, String peerId) async {
    final existing = _db.channels.where((c) =>
        c.type == ChannelType.dm &&
        c.memberIds.length == 2 &&
        c.memberIds.contains(uid) &&
        c.memberIds.contains(peerId));
    if (existing.isNotEmpty) return existing.first;
    return createChannel(
      name: '',
      type: ChannelType.dm,
      memberIds: [uid, peerId],
      createdBy: uid,
    );
  }
}

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(this._db);

  final MockDb _db;

  int _nextKeyNumber() {
    final numbers = _db.tasks
        .map((t) => int.tryParse(t.key.split('-').last) ?? 0)
        .fold<int>(100, (a, b) => a > b ? a : b);
    return numbers + 1;
  }

  @override
  Stream<List<Task>> watchTasks() => _db.watchTasks();

  @override
  Stream<List<TaskComment>> watchComments(String taskId) => _db.watchComments(taskId);

  @override
  Future<Task> createTask(Task task) async {
    final created = Task(
      id: task.id.isEmpty ? _id('k') : task.id,
      key: task.key.isEmpty ? 'CTG-${_nextKeyNumber()}' : task.key,
      title: task.title,
      reporterId: task.reporterId,
      projectId: task.projectId,
      description: task.description,
      status: task.status,
      priority: task.priority,
      type: task.type,
      assigneeIds: task.assigneeIds,
      teamId: task.teamId,
      labels: task.labels,
      progress: task.progress,
      dueAt: task.dueAt,
      estimateHours: task.estimateHours,
      checklist: task.checklist,
      attachments: task.attachments,
      watcherIds: task.watcherIds,
      groupAssignmentId: task.groupAssignmentId,
      createdAt: DateTime.now(),
      order: task.order,
    );
    _db.tasks.add(created);
    _db.pingTasks();
    return created;
  }

  @override
  Future<List<Task>> assignToGroup({
    required Task template,
    required List<String> assigneeIds,
    bool clonePerAssignee = false,
  }) async {
    final groupId = _id('g');
    if (!clonePerAssignee) {
      final task = await createTask(
        Task(
          id: '',
          key: '',
          title: template.title,
          reporterId: template.reporterId,
          description: template.description,
          status: template.status,
          priority: template.priority,
          type: template.type,
          assigneeIds: assigneeIds,
          teamId: template.teamId,
          labels: template.labels,
          dueAt: template.dueAt,
          estimateHours: template.estimateHours,
          checklist: template.checklist,
          groupAssignmentId: assigneeIds.length > 1 ? groupId : null,
          createdAt: DateTime.now(),
        ),
      );
      return [task];
    }
    final created = <Task>[];
    for (final uid in assigneeIds) {
      created.add(await createTask(
        Task(
          id: '',
          key: '',
          title: template.title,
          reporterId: template.reporterId,
          description: template.description,
          status: template.status,
          priority: template.priority,
          type: template.type,
          assigneeIds: [uid],
          teamId: template.teamId,
          labels: template.labels,
          dueAt: template.dueAt,
          estimateHours: template.estimateHours,
          checklist: template.checklist,
          groupAssignmentId: groupId,
          createdAt: DateTime.now(),
        ),
      ));
    }
    return created;
  }

  void _replace(Task task) {
    final i = _db.tasks.indexWhere((t) => t.id == task.id);
    if (i != -1) _db.tasks[i] = task;
    _db.pingTasks();
  }

  @override
  Future<void> updateTask(Task task) async =>
      _replace(task.copyWith(updatedAt: DateTime.now()));

  @override
  Future<void> setStatus(String taskId, TaskStatus status) async {
    final t = _db.tasks.firstWhere((t) => t.id == taskId);
    _replace(t.copyWith(
      status: status,
      progress: status == TaskStatus.done ? 100 : t.progress,
      completedAt: status == TaskStatus.done ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> setProgress(String taskId, int progress) async {
    final t = _db.tasks.firstWhere((t) => t.id == taskId);
    final clamped = progress.clamp(0, 100);
    _replace(t.copyWith(
      progress: clamped,
      status: clamped == 100
          ? TaskStatus.done
          : (t.status == TaskStatus.done ? TaskStatus.inProgress : t.status),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> toggleChecklistItem(String taskId, String itemId) async {
    final t = _db.tasks.firstWhere((t) => t.id == taskId);
    final items = t.checklist
        .map((c) => c.id == itemId ? c.copyWith(done: !c.done) : c)
        .toList();
    _replace(t.copyWith(checklist: items, updatedAt: DateTime.now()));
  }

  @override
  Future<void> addComment(TaskComment comment) async {
    _db.comments.putIfAbsent(comment.taskId, () => []).add(
          TaskComment(
            id: _id('tc'),
            taskId: comment.taskId,
            authorId: comment.authorId,
            text: comment.text,
            createdAt: DateTime.now(),
          ),
        );
    _db.pingComments(comment.taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _db.tasks.removeWhere((t) => t.id == taskId);
    _db.pingTasks();
  }
}

class MockAgendaRepository implements AgendaRepository {
  MockAgendaRepository(this._db);

  final MockDb _db;

  @override
  Stream<List<AgendaEvent>> watchEvents() => _db.watchEvents();

  @override
  Future<AgendaEvent> createEvent(AgendaEvent event) async {
    final created = AgendaEvent(
      id: _id('e'),
      title: event.title,
      startAt: event.startAt,
      endAt: event.endAt,
      createdBy: event.createdBy,
      description: event.description,
      allDay: event.allDay,
      location: event.location,
      meetingUrl: event.meetingUrl,
      colorValue: event.colorValue,
      attendeeIds: event.attendeeIds,
      teamIds: event.teamIds,
      rsvp: event.rsvp,
      reminderMinutes: event.reminderMinutes,
      relatedTaskId: event.relatedTaskId,
    );
    _db.events.add(created);
    _db.pingEvents();
    return created;
  }

  @override
  Future<void> updateEvent(AgendaEvent event) async {
    final i = _db.events.indexWhere((e) => e.id == event.id);
    if (i != -1) _db.events[i] = event;
    _db.pingEvents();
  }

  @override
  Future<void> setRsvp(String eventId, String uid, Rsvp rsvp) async {
    final i = _db.events.indexWhere((e) => e.id == eventId);
    if (i == -1) return;
    final map = Map<String, Rsvp>.from(_db.events[i].rsvp)..[uid] = rsvp;
    _db.events[i] = _db.events[i].copyWith(rsvp: map);
    _db.pingEvents();
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _db.events.removeWhere((e) => e.id == eventId);
    _db.pingEvents();
  }
}
