import 'dart:async';

import '../../domain/models/models.dart';

/// A tiny in-memory "database" that backs the mock repositories.
///
/// It behaves like Firestore from the UI's point of view: every read is a
/// broadcast stream that re-emits whenever the underlying list changes.
class MockDb {
  MockDb() {
    _seed();
  }

  final List<AppUser> users = [];
  final List<Team> teams = [];
  final List<Channel> channels = [];
  final Map<String, List<Message>> messages = {};
  final List<Task> tasks = [];
  final Map<String, List<TaskComment>> comments = {};
  final List<AgendaEvent> events = [];

  final _usersCtrl = StreamController<void>.broadcast();
  final _channelsCtrl = StreamController<void>.broadcast();
  final _messagesCtrl = StreamController<String>.broadcast();
  final _tasksCtrl = StreamController<void>.broadcast();
  final _commentsCtrl = StreamController<String>.broadcast();
  final _eventsCtrl = StreamController<void>.broadcast();

  void pingUsers() => _usersCtrl.add(null);
  void pingChannels() => _channelsCtrl.add(null);
  void pingMessages(String channelId) => _messagesCtrl.add(channelId);
  void pingTasks() => _tasksCtrl.add(null);
  void pingComments(String taskId) => _commentsCtrl.add(taskId);
  void pingEvents() => _eventsCtrl.add(null);

  Stream<T> _watch<T, E>(Stream<E> trigger, T Function() read,
      {bool Function(E)? where}) async* {
    yield read();
    await for (final e in trigger) {
      if (where == null || where(e)) yield read();
    }
  }

  Stream<List<AppUser>> watchUsers() =>
      _watch<List<AppUser>, void>(_usersCtrl.stream, () => List.unmodifiable(users));
  Stream<List<Team>> watchTeams() =>
      _watch<List<Team>, void>(_usersCtrl.stream, () => List.unmodifiable(teams));
  Stream<List<Channel>> watchChannels() =>
      _watch<List<Channel>, void>(_channelsCtrl.stream, () => List.unmodifiable(channels));
  Stream<List<Message>> watchMessages(String channelId) => _watch<List<Message>, String>(
        _messagesCtrl.stream,
        () => List.unmodifiable(messages[channelId] ?? const <Message>[]),
        where: (id) => id == channelId,
      );
  Stream<List<Task>> watchTasks() =>
      _watch<List<Task>, void>(_tasksCtrl.stream, () => List.unmodifiable(tasks));
  Stream<List<TaskComment>> watchComments(String taskId) => _watch<List<TaskComment>, String>(
        _commentsCtrl.stream,
        () => List.unmodifiable(comments[taskId] ?? const <TaskComment>[]),
        where: (id) => id == taskId,
      );
  Stream<List<AgendaEvent>> watchEvents() =>
      _watch<List<AgendaEvent>, void>(_eventsCtrl.stream, () => List.unmodifiable(events));

  // ---------------------------------------------------------------------------
  // Seed data — a believable snapshot of a CTG workspace.
  // ---------------------------------------------------------------------------
  void _seed() {
    final now = DateTime.now();
    DateTime at(int days, [int hour = 9, int minute = 0]) => DateTime(
          now.year,
          now.month,
          now.day + days,
          hour,
          minute,
        );

    users.addAll(const [
      AppUser(
        id: 'u1',
        displayName: 'Yasmine Bennani',
        email: 'yasmine@ctg.ma',
        title: 'Program Director',
        teamId: 't1',
        role: UserRole.admin,
        locale: 'fr',
        bio: 'Coordinates CTG programs and partnerships.',
        skills: ['Leadership', 'Partnerships'],
        online: true,
      ),
      AppUser(
        id: 'u2',
        displayName: 'Omar El Idrissi',
        email: 'omar@ctg.ma',
        title: 'Tech Lead',
        teamId: 't2',
        role: UserRole.lead,
        locale: 'en',
        bio: 'Builds the CTG platform. Flutter & Firebase.',
        skills: ['Flutter', 'Firebase', 'CI/CD'],
        online: true,
      ),
      AppUser(
        id: 'u3',
        displayName: 'Salma Ait Taleb',
        email: 'salma@ctg.ma',
        title: 'Designer',
        teamId: 't2',
        locale: 'ar',
        bio: 'UI/UX, brand and motion.',
        skills: ['Figma', 'Branding'],
      ),
      AppUser(
        id: 'u4',
        displayName: 'Mehdi Ouazzani',
        email: 'mehdi@ctg.ma',
        title: 'Events Coordinator',
        teamId: 't3',
        locale: 'fr',
        bio: 'Logistics, venues and volunteers.',
        skills: ['Logistics', 'Community'],
      ),
      AppUser(
        id: 'u5',
        displayName: 'Nour Haddad',
        email: 'nour@ctg.ma',
        title: 'Communications',
        teamId: 't3',
        locale: 'ar',
        bio: 'Social media and press.',
        skills: ['Copywriting', 'Social'],
        online: true,
      ),
      AppUser(
        id: 'u6',
        displayName: 'Anas Rahmouni',
        email: 'anas@ctg.ma',
        title: 'Developer',
        teamId: 't2',
        locale: 'en',
        bio: 'Backend and data.',
        skills: ['Node', 'Firestore'],
      ),
    ]);

    teams.addAll(const [
      Team(id: 't1', name: 'Core', memberIds: ['u1'], leadId: 'u1', colorValue: 0xFF6B4A32),
      Team(
        id: 't2',
        name: 'Tech',
        memberIds: ['u2', 'u3', 'u6'],
        leadId: 'u2',
        colorValue: 0xFF3E6B52,
      ),
      Team(
        id: 't3',
        name: 'Events & Comms',
        memberIds: ['u4', 'u5'],
        leadId: 'u4',
        colorValue: 0xFF6E2C2C,
      ),
    ]);

    final everyone = users.map((u) => u.id).toList();
    channels.addAll([
      Channel(
        id: 'c_general',
        name: 'general',
        type: ChannelType.general,
        topic: 'Everything CTG — announcements and daily chatter',
        memberIds: everyone,
        createdBy: 'u1',
        lastMessageAt: now.subtract(const Duration(minutes: 8)),
      ),
      Channel(
        id: 'c_tech',
        name: 'tech',
        type: ChannelType.public,
        topic: 'Platform, releases, bugs',
        memberIds: const ['u1', 'u2', 'u3', 'u6'],
        createdBy: 'u2',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
      ),
      Channel(
        id: 'c_events',
        name: 'events',
        type: ChannelType.public,
        topic: 'CTG Day, meetups, logistics',
        memberIds: const ['u1', 'u4', 'u5'],
        createdBy: 'u4',
        lastMessageAt: now.subtract(const Duration(hours: 5)),
      ),
      Channel(
        id: 'c_board',
        name: 'board',
        type: ChannelType.private,
        topic: 'Leads only',
        memberIds: const ['u1', 'u2', 'u4'],
        createdBy: 'u1',
        lastMessageAt: now.subtract(const Duration(days: 1)),
      ),
      Channel(
        id: 'c_dm_1_2',
        name: '',
        type: ChannelType.dm,
        memberIds: const ['u1', 'u2'],
        lastMessageAt: now.subtract(const Duration(minutes: 40)),
      ),
      Channel(
        id: 'c_dm_2_3',
        name: '',
        type: ChannelType.dm,
        memberIds: const ['u2', 'u3'],
        lastMessageAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);

    void msg(
      String id,
      String channelId,
      String senderId,
      String text,
      Duration ago, {
      MessageType type = MessageType.text,
      List<Attachment> attachments = const [],
      String? taskId,
      String? linkUrl,
      Map<String, List<String>> reactions = const {},
    }) {
      messages.putIfAbsent(channelId, () => []).add(Message(
            id: id,
            channelId: channelId,
            senderId: senderId,
            sentAt: now.subtract(ago),
            text: text,
            type: type,
            attachments: attachments,
            taskId: taskId,
            linkUrl: linkUrl,
            reactions: reactions,
          ));
    }

    msg('m1', 'c_general', 'u1',
        'Good morning everyone. Reminder: the CTG Day planning review is on Thursday.',
        const Duration(hours: 6),
        reactions: const {'ack': ['u2', 'u5'], 'agree': ['u3']});
    msg('m2', 'c_general', 'u5', 'The new poster draft is ready, feedback welcome!', const Duration(hours: 5),
        type: MessageType.image,
        attachments: const [
          Attachment(url: 'https://picsum.photos/seed/ctgposter/900/600', name: 'ctg-day-poster.png', mime: 'image/png', sizeBytes: 842000)
        ]);
    msg('m3', 'c_general', 'u2', 'Nice! I linked it to the design task.', const Duration(hours: 4),
        type: MessageType.taskRef, taskId: 'k3');
    msg('m4', 'c_general', 'u4', 'Venue confirmation PDF attached.', const Duration(hours: 3),
        type: MessageType.file,
        attachments: const [
          Attachment(url: '#', name: 'venue-contract.pdf', mime: 'application/pdf', sizeBytes: 231000)
        ]);
    msg('m5', 'c_general', 'u3', 'Playlist for the closing session', const Duration(hours: 2),
        type: MessageType.audio,
        attachments: const [
          Attachment(url: '#', name: 'ctg-day-mix.mp3', mime: 'audio/mpeg', sizeBytes: 5300000, durationMs: 184000)
        ]);
    msg('m6', 'c_general', 'u6', 'Useful read on Firestore pricing', const Duration(minutes: 8),
        type: MessageType.link, linkUrl: 'https://firebase.google.com/docs/firestore/pricing');

    msg('m10', 'c_tech', 'u2', 'Release 0.4 is on staging, please test the agenda view.', const Duration(hours: 3));
    msg('m11', 'c_tech', 'u6', 'Found a bug with recurring events, opening a ticket.', const Duration(hours: 2),
        reactions: const {'watching': ['u2']});
    msg('m20', 'c_events', 'u4', 'Catering quote received — 120 people.', const Duration(hours: 5));
    msg('m30', 'c_board', 'u1', 'Budget review notes shared.', const Duration(days: 1));
    msg('m40', 'c_dm_1_2', 'u1', 'Can you assign the onboarding tasks to the new members today?',
        const Duration(minutes: 45));
    msg('m41', 'c_dm_1_2', 'u2', 'Already done, assigned as a group task.', const Duration(minutes: 40));
    msg('m50', 'c_dm_2_3', 'u3', 'Sending the updated palette now.', const Duration(hours: 3));

    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      final last = messages[c.id]?.last;
      if (last != null) {
        channels[i] = c.copyWith(
          lastMessageText: last.text,
          lastMessageAt: last.sentAt,
          lastMessageSenderId: last.senderId,
        );
      }
    }

    tasks.addAll([
      Task(
        id: 'k1',
        key: 'CTG-101',
        title: 'Finalize CTG Day agenda',
        description: 'Collect the talk list, confirm speakers and publish the schedule.',
        reporterId: 'u1',
        assigneeIds: const ['u4', 'u5'],
        teamId: 't3',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        progress: 60,
        labels: const ['ctg-day', 'planning'],
        dueAt: at(3, 17),
        estimateHours: 8,
        createdAt: now.subtract(const Duration(days: 6)),
        checklist: const [
          ChecklistItem(id: 'a', text: 'Collect talk proposals', done: true),
          ChecklistItem(id: 'b', text: 'Confirm speakers', done: true),
          ChecklistItem(id: 'c', text: 'Publish schedule'),
        ],
      ),
      Task(
        id: 'k2',
        key: 'CTG-102',
        title: 'Fix recurring events bug',
        description: 'Weekly events repeat one day off in the month view.',
        reporterId: 'u6',
        assigneeIds: const ['u2'],
        teamId: 't2',
        status: TaskStatus.todo,
        type: TaskType.bug,
        priority: TaskPriority.urgent,
        labels: const ['agenda', 'bug'],
        dueAt: at(1, 12),
        estimateHours: 3,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'k3',
        key: 'CTG-103',
        title: 'CTG Day poster & social kit',
        description: 'Poster, story templates and a cover image in 3 languages.',
        reporterId: 'u1',
        assigneeIds: const ['u3'],
        teamId: 't2',
        status: TaskStatus.review,
        type: TaskType.feature,
        priority: TaskPriority.medium,
        progress: 90,
        labels: const ['design'],
        dueAt: at(2, 18),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Task(
        id: 'k4',
        key: 'CTG-104',
        title: 'Onboard new members (welcome pack)',
        description: 'Send the welcome pack, add to #general, schedule intro call.',
        reporterId: 'u2',
        assigneeIds: const ['u3', 'u5', 'u6'],
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        groupAssignmentId: 'g-onboarding',
        labels: const ['onboarding'],
        dueAt: at(5, 17),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'k5',
        key: 'CTG-105',
        title: 'Publish quarterly newsletter',
        reporterId: 'u1',
        assigneeIds: const ['u5'],
        teamId: 't3',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        progress: 100,
        createdAt: now.subtract(const Duration(days: 12)),
        completedAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'k6',
        key: 'CTG-106',
        title: 'Sponsor deck v2',
        description: 'Update numbers and add the 2026 program roadmap.',
        reporterId: 'u1',
        assigneeIds: const ['u1', 'u3'],
        status: TaskStatus.backlog,
        priority: TaskPriority.medium,
        dueAt: at(14, 17),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    comments['k1'] = [
      TaskComment(
        id: 'tc1',
        taskId: 'k1',
        authorId: 'u5',
        text: 'Two speakers still have not confirmed, I will follow up today.',
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
      TaskComment(
        id: 'tc2',
        taskId: 'k1',
        authorId: 'u1',
        text: 'Thanks — let us lock the schedule before Thursday.',
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
    ];

    events.addAll([
      AgendaEvent(
        id: 'e1',
        title: 'Weekly CTG standup',
        description: 'Quick round of updates from every team.',
        startAt: at(0, 10),
        endAt: at(0, 10, 30),
        createdBy: 'u1',
        location: 'Meeting room A',
        meetingUrl: 'https://meet.ctg.ma/standup',
        colorValue: 0xFF2E4A3A,
        attendeeIds: everyone,
      ),
      AgendaEvent(
        id: 'e2',
        title: 'CTG Day planning review',
        startAt: at(3, 15),
        endAt: at(3, 16, 30),
        createdBy: 'u4',
        location: 'Hybrid',
        colorValue: 0xFF6E2C2C,
        attendeeIds: const ['u1', 'u4', 'u5'],
        teamIds: const ['t3'],
      ),
      AgendaEvent(
        id: 'e3',
        title: 'Design review — poster & social kit',
        startAt: at(1, 14),
        endAt: at(1, 15),
        createdBy: 'u2',
        colorValue: 0xFF3E6B52,
        attendeeIds: const ['u2', 'u3', 'u1'],
        relatedTaskId: 'k3',
      ),
      AgendaEvent(
        id: 'e4',
        title: 'CTG Day',
        startAt: at(9, 9),
        endAt: at(9, 18),
        allDay: true,
        createdBy: 'u1',
        location: 'Agadir — Technopark',
        colorValue: 0xFF6B4A32,
        attendeeIds: everyone,
      ),
      AgendaEvent(
        id: 'e5',
        title: 'Release 0.4 to production',
        startAt: at(5, 11),
        endAt: at(5, 12),
        createdBy: 'u2',
        colorValue: 0xFF3E6B52,
        attendeeIds: const ['u2', 'u6'],
      ),
    ]);
  }
}
