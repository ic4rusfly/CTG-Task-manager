import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Firestore implementation of [TaskRepository].
class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tasks => _db.collection('tasks');

  @override
  Stream<List<Task>> watchTasks() => _tasks
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Task.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<TaskComment>> watchComments(String taskId) => _tasks
      .doc(taskId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => TaskComment.fromMap(d.id, taskId, d.data())).toList());

  Future<String> _nextKey() async {
    // A counter document keeps CTG-### keys sequential without a scan.
    final ref = _db.collection('counters').doc('tasks');
    return _db.runTransaction<String>((tx) async {
      final snap = await tx.get(ref);
      final next = ((snap.data()?['value'] as int?) ?? 100) + 1;
      tx.set(ref, {'value': next}, SetOptions(merge: true));
      return 'CTG-$next';
    });
  }

  @override
  Future<Task> createTask(Task task) async {
    final key = task.key.isEmpty ? await _nextKey() : task.key;
    final doc = _tasks.doc();
    final data = task.toMap()
      ..['key'] = key
      ..['createdAt'] = DateTime.now().toIso8601String();
    await doc.set(data);
    return Task.fromMap(doc.id, data);
  }

  @override
  Future<List<Task>> assignToGroup({
    required Task template,
    required List<String> assigneeIds,
    bool clonePerAssignee = false,
  }) async {
    final groupId = _db.collection('tasks').doc().id;
    if (!clonePerAssignee) {
      return [
        await createTask(template.copyWith(
          assigneeIds: assigneeIds,
        )),
      ];
    }
    final batchResults = <Task>[];
    for (final uid in assigneeIds) {
      final created = await createTask(template.copyWith(assigneeIds: [uid]));
      await _tasks.doc(created.id).update({'groupAssignmentId': groupId});
      batchResults.add(created);
    }
    return batchResults;
  }

  @override
  Future<void> updateTask(Task task) =>
      _tasks.doc(task.id).update(task.toMap()..['updatedAt'] = DateTime.now().toIso8601String());

  @override
  Future<void> setStatus(String taskId, TaskStatus status) => _tasks.doc(taskId).update({
        'status': status.name,
        if (status == TaskStatus.done) 'progress': 100,
        'completedAt': status == TaskStatus.done ? DateTime.now().toIso8601String() : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

  @override
  Future<void> setProgress(String taskId, int progress) => _tasks.doc(taskId).update({
        'progress': progress.clamp(0, 100),
        'updatedAt': DateTime.now().toIso8601String(),
      });

  @override
  Future<void> toggleChecklistItem(String taskId, String itemId) async {
    final ref = _tasks.doc(taskId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final task = Task.fromMap(snap.id, snap.data()!);
      final items = task.checklist
          .map((c) => c.id == itemId ? c.copyWith(done: !c.done) : c)
          .map((c) => c.toMap())
          .toList();
      tx.update(ref, {'checklist': items});
    });
  }

  @override
  Future<void> addComment(TaskComment comment) =>
      _tasks.doc(comment.taskId).collection('comments').add(comment.toMap());

  @override
  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();
}
