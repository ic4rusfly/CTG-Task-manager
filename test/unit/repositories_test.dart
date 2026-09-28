import 'package:ctg_hub/data/mock/mock_db.dart';
import 'package:ctg_hub/data/mock/mock_repositories.dart';
import 'package:ctg_hub/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDb db;
  late MockTaskRepository tasks;
  late MockChatRepository chat;
  late MockAgendaRepository agenda;

  setUp(() {
    db = MockDb();
    tasks = MockTaskRepository(db);
    chat = MockChatRepository(db);
    agenda = MockAgendaRepository(db);
  });

  Task template() => Task(
        id: '',
        key: '',
        title: 'Onboard new members',
        reporterId: 'u1',
        createdAt: DateTime.now(),
      );

  group('group assignment', () {
    test('one shared task keeps every assignee on a single card', () async {
      final created = await tasks.assignToGroup(
        template: template(),
        assigneeIds: ['u3', 'u5', 'u6'],
      );

      expect(created, hasLength(1));
      expect(created.single.assigneeIds, ['u3', 'u5', 'u6']);
      expect(created.single.groupAssignmentId, isNotNull);
      expect(created.single.key, startsWith('CTG-'));
    });

    test('clone per assignee creates one task each, sharing a group id', () async {
      final created = await tasks.assignToGroup(
        template: template(),
        assigneeIds: ['u3', 'u5', 'u6'],
        clonePerAssignee: true,
      );

      expect(created, hasLength(3));
      expect(created.map((t) => t.assigneeIds.single), ['u3', 'u5', 'u6']);
      expect(created.map((t) => t.groupAssignmentId).toSet(), hasLength(1));
      expect(created.map((t) => t.key).toSet(), hasLength(3), reason: 'keys must be unique');
    });
  });

  group('task updates', () {
    test('moving to done forces progress to 100', () async {
      await tasks.setStatus('k1', TaskStatus.done);
      final task = db.tasks.firstWhere((t) => t.id == 'k1');
      expect(task.progress, 100);
      expect(task.completedAt, isNotNull);
    });

    test('setting progress to 100 marks the task done', () async {
      await tasks.setProgress('k2', 100);
      expect(db.tasks.firstWhere((t) => t.id == 'k2').status, TaskStatus.done);
    });

    test('toggling a checklist item recomputes the derived progress', () async {
      await tasks.toggleChecklistItem('k1', 'c');
      final task = db.tasks.firstWhere((t) => t.id == 'k1');
      expect(task.checklistDone, 3);
      expect(task.effectiveProgress, 100);
    });
  });

  group('chat', () {
    test('sending a message updates the channel preview', () async {
      await chat.sendMessage(Message(
        id: '',
        channelId: 'c_general',
        senderId: 'u2',
        sentAt: DateTime.now(),
        text: 'Standup in five minutes',
      ));

      final channel = db.channels.firstWhere((c) => c.id == 'c_general');
      expect(channel.lastMessageText, 'Standup in five minutes');
      expect(channel.lastMessageSenderId, 'u2');
    });

    test('openDm reuses an existing conversation', () async {
      final first = await chat.openDm('u1', 'u2');
      final again = await chat.openDm('u2', 'u1');
      expect(again.id, first.id);
    });

    test('openDm creates a conversation when there is none', () async {
      final channel = await chat.openDm('u1', 'u6');
      expect(channel.type, ChannelType.dm);
      expect(channel.memberIds, containsAll(<String>['u1', 'u6']));
    });

    test('reactions toggle on and off', () async {
      await chat.toggleReaction('c_general', 'm1', 'ack', 'u3');
      expect(db.messages['c_general']!.first.reactions['ack'], contains('u3'));

      await chat.toggleReaction('c_general', 'm1', 'ack', 'u3');
      expect(db.messages['c_general']!.first.reactions['ack'], isNot(contains('u3')));
    });
  });

  test('agenda rsvp is stored per member', () async {
    await agenda.setRsvp('e1', 'u3', Rsvp.going);
    expect(db.events.firstWhere((e) => e.id == 'e1').rsvp['u3'], Rsvp.going);
  });

  group('notifications', notificationTests);
}

// ---------------------------------------------------------------------------
// Notifications: composed in the recipient's language, exactly like the
// Cloud Functions do in production.
// ---------------------------------------------------------------------------
void notificationTests() {
  late MockDb db;
  late MockNotificationRepository notifications;
  late MockNotifier notifier;
  late MockTaskRepository tasks;
  late MockChatRepository chat;

  setUp(() {
    db = MockDb();
    notifications = MockNotificationRepository(db);
    notifier = MockNotifier(db, notifications);
    tasks = MockTaskRepository(db, notifier);
    chat = MockChatRepository(db, notifier);
  });

  test('assigning a task notifies every assignee but not the reporter', () async {
    await tasks.assignToGroup(
      template: Task(
        id: '',
        key: '',
        title: 'Prepare sponsor emails',
        reporterId: 'u1',
        createdAt: DateTime.now(),
      ),
      assigneeIds: ['u1', 'u3', 'u5'],
    );

    expect(db.notifications['u1']?.where((n) => n.kind == NotificationKind.taskAssigned) ?? [],
        isEmpty);
    expect(db.notifications['u3'], hasLength(1));
    expect(db.notifications['u5'], hasLength(1));
  });

  test('notification copy uses the recipient locale', () async {
    await tasks.assignToGroup(
      template: Task(
        id: '',
        key: '',
        title: 'Prepare sponsor emails',
        reporterId: 'u2',
        createdAt: DateTime.now(),
      ),
      assigneeIds: ['u3', 'u6'], // u3 reads Arabic, u6 reads English
    );

    expect(db.notifications['u3']!.single.title, contains('أسند'));
    expect(db.notifications['u6']!.single.title, contains('assigned'));
  });

  test('mentioning someone in a message notifies them', () async {
    await chat.sendMessage(Message(
      id: '',
      channelId: 'c_general',
      senderId: 'u1',
      sentAt: DateTime.now(),
      text: 'can you look at this @Omar',
      mentions: const ['u2'],
    ));

    final item = db.notifications['u2']!.single;
    expect(item.kind, NotificationKind.mention);
    expect(item.route, '/chat/c_general');
  });

  test('markAllRead clears the unread badge', () async {
    await notifications.add(AppNotification(
      id: '',
      uid: 'u2',
      kind: NotificationKind.message,
      title: 'x',
      body: 'y',
      route: '/chat/c_general',
      createdAt: DateTime.now(),
    ));
    await notifications.markAllRead('u2');
    expect(db.notifications['u2']!.every((n) => n.read), isTrue);
  });
}
