import '../domain/models/enums.dart';
import '../l10n/app_localizations.dart';

String statusLabel(AppLocalizations t, TaskStatus s) => switch (s) {
      TaskStatus.backlog => t.statusBacklog,
      TaskStatus.todo => t.statusTodo,
      TaskStatus.inProgress => t.statusInProgress,
      TaskStatus.review => t.statusReview,
      TaskStatus.done => t.statusDone,
      TaskStatus.blocked => t.statusBlocked,
    };

String priorityLabel(AppLocalizations t, TaskPriority p) => switch (p) {
      TaskPriority.low => t.priorityLow,
      TaskPriority.medium => t.priorityMedium,
      TaskPriority.high => t.priorityHigh,
      TaskPriority.urgent => t.priorityUrgent,
    };

String typeLabel(AppLocalizations t, TaskType ty) => switch (ty) {
      TaskType.task => t.typeTask,
      TaskType.bug => t.typeBug,
      TaskType.feature => t.typeFeature,
    };

String roleLabel(AppLocalizations t, UserRole r) => switch (r) {
      UserRole.member => t.roleMember,
      UserRole.lead => t.roleLead,
      UserRole.admin => t.roleAdmin,
    };

String rsvpLabel(AppLocalizations t, Rsvp r) => switch (r) {
      Rsvp.going => t.going,
      Rsvp.maybe => t.maybe,
      Rsvp.no => t.declined,
    };

String languageLabel(String code) => switch (code) {
      'ar' => 'العربية',
      'fr' => 'Français',
      _ => 'English',
    };

/// Message reactions are named codes (never emoji) so they render identically
/// on every platform and stay translatable.
const kReactionCodes = <String>['ack', 'agree', 'watching', 'blocker', 'done'];

String reactionLabel(AppLocalizations t, String code) => switch (code) {
      'ack' => t.reactionAck,
      'agree' => t.reactionAgree,
      'watching' => t.reactionWatching,
      'blocker' => t.reactionBlocker,
      _ => t.reactionDone,
    };
