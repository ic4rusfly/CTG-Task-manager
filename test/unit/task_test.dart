import 'package:ctg_hub/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Task sample({
  TaskStatus status = TaskStatus.todo,
  int progress = 0,
  List<ChecklistItem> checklist = const [],
  DateTime? dueAt,
}) =>
    Task(
      id: 'k1',
      key: 'CTG-101',
      title: 'Finalize CTG Day agenda',
      reporterId: 'u1',
      status: status,
      progress: progress,
      checklist: checklist,
      dueAt: dueAt,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Task.effectiveProgress', () {
    test('uses the manual percentage when there is no checklist', () {
      expect(sample(progress: 40).effectiveProgress, 40);
    });

    test('is derived from the checklist when one exists', () {
      final task = sample(progress: 0, checklist: const [
        ChecklistItem(id: 'a', text: 'one', done: true),
        ChecklistItem(id: 'b', text: 'two', done: true),
        ChecklistItem(id: 'c', text: 'three'),
      ]);
      expect(task.effectiveProgress, 67);
      expect(task.checklistDone, 2);
    });

    test('a done task always reports 100', () {
      expect(sample(status: TaskStatus.done, progress: 10).effectiveProgress, 100);
    });
  });

  group('Task.isOverdue', () {
    test('true for a past due date on an open task', () {
      expect(sample(dueAt: DateTime.now().subtract(const Duration(days: 1))).isOverdue, isTrue);
    });

    test('false once the task is done', () {
      final task = sample(
        status: TaskStatus.done,
        dueAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, isFalse);
    });

    test('false when there is no due date', () {
      expect(sample().isOverdue, isFalse);
    });
  });

  test('round trips through toMap / fromMap', () {
    final task = sample(
      status: TaskStatus.review,
      progress: 90,
      dueAt: DateTime(2026, 3, 12, 17),
      checklist: const [ChecklistItem(id: 'a', text: 'one', done: true)],
    );
    final copy = Task.fromMap(task.id, task.toMap());

    expect(copy.key, task.key);
    expect(copy.status, TaskStatus.review);
    expect(copy.progress, 90);
    expect(copy.dueAt, task.dueAt);
    expect(copy.checklist.single.done, isTrue);
  });

  test('unknown enum values fall back instead of throwing', () {
    final task = Task.fromMap('k9', {
      'key': 'CTG-999',
      'title': 'Legacy row',
      'reporterId': 'u1',
      'status': 'archived',
      'priority': 'insane',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    expect(task.status, TaskStatus.todo);
    expect(task.priority, TaskPriority.medium);
  });
}
