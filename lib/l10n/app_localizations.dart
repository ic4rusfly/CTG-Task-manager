// GENERATED FILE - do not edit by hand.
//
// Regenerate with:  python3 tool/gen_l10n.py
// Source of truth:  lib/l10n/app_en.arb  (+ app_fr.arb, app_ar.arb)
//
// A dependency-free localization delegate: it behaves like `flutter gen-l10n`
// output but needs no code-generation step to build the app.
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  Map<String, String> get _s => _strings[localeName] ?? _strings['en']!;

  String _get(String key) => _s[key] ?? _strings['en']![key] ?? key;

  String get appName => _get('appName');
  String get tagline => _get('tagline');
  String get signIn => _get('signIn');
  String get signOut => _get('signOut');
  String get email => _get('email');
  String get password => _get('password');
  String get demoSignInHint => _get('demoSignInHint');
  String get unknownUser => _get('unknownUser');
  String get chat => _get('chat');
  String get tasks => _get('tasks');
  String get agenda => _get('agenda');
  String get members => _get('members');
  String get profile => _get('profile');
  String get admin => _get('admin');
  String get settings => _get('settings');
  String get channels => _get('channels');
  String get directMessages => _get('directMessages');
  String get newChannel => _get('newChannel');
  String get newMessage => _get('newMessage');
  String get messageHint => _get('messageHint');
  String get send => _get('send');
  String get attachImage => _get('attachImage');
  String get attachFile => _get('attachFile');
  String get attachAudio => _get('attachAudio');
  String get attachLink => _get('attachLink');
  String get linkTask => _get('linkTask');
  String get reply => _get('reply');
  String get deleteMessage => _get('deleteMessage');
  String get messageDeleted => _get('messageDeleted');
  String get today => _get('today');
  String get yesterday => _get('yesterday');
  String get justNow => _get('justNow');
  String get board => _get('board');
  String get list => _get('list');
  String get myTasks => _get('myTasks');
  String get allTasks => _get('allTasks');
  String get newTask => _get('newTask');
  String get editTask => _get('editTask');
  String get taskTitle => _get('taskTitle');
  String get description => _get('description');
  String get status => _get('status');
  String get priority => _get('priority');
  String get type => _get('type');
  String get assignees => _get('assignees');
  String get reporter => _get('reporter');
  String get team => _get('team');
  String get labels => _get('labels');
  String get progress => _get('progress');
  String get dueDate => _get('dueDate');
  String get estimate => _get('estimate');
  String get checklist => _get('checklist');
  String get attachments => _get('attachments');
  String get comments => _get('comments');
  String get addComment => _get('addComment');
  String get activity => _get('activity');
  String get statusBacklog => _get('statusBacklog');
  String get statusTodo => _get('statusTodo');
  String get statusInProgress => _get('statusInProgress');
  String get statusReview => _get('statusReview');
  String get statusDone => _get('statusDone');
  String get statusBlocked => _get('statusBlocked');
  String get priorityLow => _get('priorityLow');
  String get priorityMedium => _get('priorityMedium');
  String get priorityHigh => _get('priorityHigh');
  String get priorityUrgent => _get('priorityUrgent');
  String get typeTask => _get('typeTask');
  String get typeBug => _get('typeBug');
  String get typeFeature => _get('typeFeature');
  String get overdue => _get('overdue');
  String get dueSoon => _get('dueSoon');
  String get noTasks => _get('noTasks');
  String get assignToGroup => _get('assignToGroup');
  String get assignMode => _get('assignMode');
  String get sharedTask => _get('sharedTask');
  String get oneTaskEach => _get('oneTaskEach');
  String get selectPeople => _get('selectPeople');
  String get selectTeam => _get('selectTeam');
  String get assign => _get('assign');
  String get assigned => _get('assigned');
  String get newEvent => _get('newEvent');
  String get eventTitle => _get('eventTitle');
  String get startsAt => _get('startsAt');
  String get endsAt => _get('endsAt');
  String get allDay => _get('allDay');
  String get location => _get('location');
  String get meetingLink => _get('meetingLink');
  String get attendees => _get('attendees');
  String get going => _get('going');
  String get maybe => _get('maybe');
  String get declined => _get('declined');
  String get noEvents => _get('noEvents');
  String get upcoming => _get('upcoming');
  String get month => _get('month');
  String get day => _get('day');
  String get language => _get('language');
  String get theme => _get('theme');
  String get themeSystem => _get('themeSystem');
  String get themeLight => _get('themeLight');
  String get themeDark => _get('themeDark');
  String get notifications => _get('notifications');
  String get account => _get('account');
  String get role => _get('role');
  String get roleMember => _get('roleMember');
  String get roleLead => _get('roleLead');
  String get roleAdmin => _get('roleAdmin');
  String get title => _get('title');
  String get phone => _get('phone');
  String get bio => _get('bio');
  String get skills => _get('skills');
  String get message => _get('message');
  String get assignTask => _get('assignTask');
  String get searchMembers => _get('searchMembers');
  String get searchTasks => _get('searchTasks');
  String get manageMembers => _get('manageMembers');
  String get deactivate => _get('deactivate');
  String get activate => _get('activate');
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get delete => _get('delete');
  String get create => _get('create');
  String get close => _get('close');
  String get online => _get('online');
  String get offline => _get('offline');
  String get adminOnly => _get('adminOnly');
  String get overviewOpenTasks => _get('overviewOpenTasks');
  String get overviewDueThisWeek => _get('overviewDueThisWeek');
  String get overviewUnread => _get('overviewUnread');
  String get reactionAck => _get('reactionAck');
  String get reactionAgree => _get('reactionAgree');
  String get reactionWatching => _get('reactionWatching');
  String get reactionBlocker => _get('reactionBlocker');
  String get reactionDone => _get('reactionDone');
  String get search => _get('search');
  String get searchMessages => _get('searchMessages');
  String get noResults => _get('noResults');
  String get notificationCenter => _get('notificationCenter');
  String get markAllRead => _get('markAllRead');
  String get noNotifications => _get('noNotifications');
  String get mentionSomeone => _get('mentionSomeone');
  String get openConversation => _get('openConversation');
  String get thread => _get('thread');
  String get replyInThread => _get('replyInThread');
  String get threadReplyHint => _get('threadReplyHint');
  String get uploading => _get('uploading');
  String get uploadFailed => _get('uploadFailed');
  String get retry => _get('retry');
  String get openFile => _get('openFile');
  String get pushNotifications => _get('pushNotifications');
  String get pushOnThisDevice => _get('pushOnThisDevice');
  String get pushBlocked => _get('pushBlocked');
  String get pushUnsupported => _get('pushUnsupported');
  String get deviceRegistered => _get('deviceRegistered');
  String get open => _get('open');
  String get errorTitle => _get('errorTitle');
  String get errorBody => _get('errorBody');
  String get loading => _get('loading');
  String get signedOut => _get('signedOut');
  String get mute => _get('mute');
  String get unmute => _get('unmute');
  String get muted => _get('muted');
  String get mutedHint => _get('mutedHint');
  String get seen => _get('seen');
  String get sent => _get('sent');
  String get addAttachment => _get('addAttachment');
  String get noAttachments => _get('noAttachments');
  String get removeAttachment => _get('removeAttachment');
  String get edit => _get('edit');
  String get edited => _get('edited');
  String get editMessage => _get('editMessage');
  String get noActivity => _get('noActivity');

  String minutesAgo(int count) {
    var s = _get('minutesAgo');
    s = s.replaceAll('{count}', '$count');
    return s;
  }
  String hoursAgo(int count) {
    var s = _get('hoursAgo');
    s = s.replaceAll('{count}', '$count');
    return s;
  }
  String daysAgo(int count) {
    var s = _get('daysAgo');
    s = s.replaceAll('{count}', '$count');
    return s;
  }
  String membersCount(int count) => _plural('membersCount', count);
  String tasksCreated(int count) {
    var s = _get('tasksCreated');
    s = s.replaceAll('{count}', '$count');
    return s;
  }
  String welcomeBack(Object name) {
    var s = _get('welcomeBack');
    s = s.replaceAll('{name}', '$name');
    return s;
  }
  String unreadCount(int count) => _plural('unreadCount', count);
  String mentionedYou(Object name) {
    var s = _get('mentionedYou');
    s = s.replaceAll('{name}', '$name');
    return s;
  }
  String assignedYouTask(Object name, Object key) {
    var s = _get('assignedYouTask');
    s = s.replaceAll('{name}', '$name');
    s = s.replaceAll('{key}', '$key');
    return s;
  }
  String inChannel(Object channel) {
    var s = _get('inChannel');
    s = s.replaceAll('{channel}', '$channel');
    return s;
  }
  String resultsCount(int count) => _plural('resultsCount', count);
  String repliesCount(int count) => _plural('repliesCount', count);
  String repliedToYou(Object name) {
    var s = _get('repliedToYou');
    s = s.replaceAll('{name}', '$name');
    return s;
  }
  String fileTooLarge(Object limit) {
    var s = _get('fileTooLarge');
    s = s.replaceAll('{limit}', '$limit');
    return s;
  }
  String seenByCount(int count) => _plural('seenByCount', count);
  String activityCreated(Object name) {
    var s = _get('activityCreated');
    s = s.replaceAll('{name}', '$name');
    return s;
  }
  String activityStatus(Object name, Object status) {
    var s = _get('activityStatus');
    s = s.replaceAll('{name}', '$name');
    s = s.replaceAll('{status}', '$status');
    return s;
  }
  String activityProgress(Object name, Object value) {
    var s = _get('activityProgress');
    s = s.replaceAll('{name}', '$name');
    s = s.replaceAll('{value}', '$value');
    return s;
  }
  String activityAssigned(Object name, Object people) {
    var s = _get('activityAssigned');
    s = s.replaceAll('{name}', '$name');
    s = s.replaceAll('{people}', '$people');
    return s;
  }
  String activityAttached(Object name, Object file) {
    var s = _get('activityAttached');
    s = s.replaceAll('{name}', '$name');
    s = s.replaceAll('{file}', '$file');
    return s;
  }

  /// Minimal ICU plural support for the few plural keys we use.
  String _plural(String key, int count) {
    final raw = _get(key);
    final match = RegExp(r'\{count,\s*plural,\s*(.*)\}\s*$', dotAll: true).firstMatch(raw);
    if (match == null) return raw.replaceAll('{count}', '$count');
    final body = match.group(1)!;
    final cases = <String, String>{};
    final re = RegExp(r'(=\d+|zero|one|two|few|many|other)\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}');
    for (final m in re.allMatches(body)) {
      cases[m.group(1)!] = m.group(2)!;
    }
    String? pick = cases['=$count'];
    pick ??= _category(count, cases);
    pick ??= cases['other'] ?? raw;
    return pick.replaceAll('{count}', '$count');
  }

  String? _category(int count, Map<String, String> cases) {
    if (localeName == 'ar') {
      if (count == 0) return cases['zero'];
      if (count == 1) return cases['one'];
      if (count == 2) return cases['two'];
      final mod100 = count % 100;
      if (mod100 >= 3 && mod100 <= 10) return cases['few'];
      if (mod100 >= 11) return cases['many'];
      return cases['other'];
    }
    if (count == 1) return cases['one'];
    return cases['other'];
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _strings = <String, Map<String, String>>{
  'en': <String, String>{
    'appName': 'CTG Hub',
    'tagline': 'Chat, tasks and agenda for CTG members',
    'signIn': 'Sign in',
    'signOut': 'Sign out',
    'email': 'Email',
    'password': 'Password',
    'demoSignInHint': 'Demo mode — pick a member to sign in as',
    'unknownUser': 'No CTG member found with this email',
    'chat': 'Chat',
    'tasks': 'Tasks',
    'agenda': 'Agenda',
    'members': 'Members',
    'profile': 'Profile',
    'admin': 'Admin',
    'settings': 'Settings',
    'channels': 'Channels',
    'directMessages': 'Direct messages',
    'newChannel': 'New channel',
    'newMessage': 'New message',
    'messageHint': 'Write a message…',
    'send': 'Send',
    'attachImage': 'Image',
    'attachFile': 'File',
    'attachAudio': 'Audio',
    'attachLink': 'Link',
    'linkTask': 'Link a task',
    'reply': 'Reply',
    'deleteMessage': 'Delete message',
    'messageDeleted': 'Message deleted',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'justNow': 'now',
    'minutesAgo': '{count}m',
    'hoursAgo': '{count}h',
    'daysAgo': '{count}d',
    'membersCount': '{count, plural, =0{No members} =1{1 member} other{{count} members}}',
    'board': 'Board',
    'list': 'List',
    'myTasks': 'My tasks',
    'allTasks': 'All tasks',
    'newTask': 'New task',
    'editTask': 'Edit task',
    'taskTitle': 'Title',
    'description': 'Description',
    'status': 'Status',
    'priority': 'Priority',
    'type': 'Type',
    'assignees': 'Assignees',
    'reporter': 'Reporter',
    'team': 'Team',
    'labels': 'Labels',
    'progress': 'Progress',
    'dueDate': 'Due date',
    'estimate': 'Estimate (h)',
    'checklist': 'Checklist',
    'attachments': 'Attachments',
    'comments': 'Comments',
    'addComment': 'Add a comment…',
    'activity': 'Activity',
    'statusBacklog': 'Backlog',
    'statusTodo': 'To do',
    'statusInProgress': 'In progress',
    'statusReview': 'Review',
    'statusDone': 'Done',
    'statusBlocked': 'Blocked',
    'priorityLow': 'Low',
    'priorityMedium': 'Medium',
    'priorityHigh': 'High',
    'priorityUrgent': 'Urgent',
    'typeTask': 'Task',
    'typeBug': 'Bug',
    'typeFeature': 'Feature',
    'overdue': 'Overdue',
    'dueSoon': 'Due soon',
    'noTasks': 'No tasks here yet',
    'assignToGroup': 'Assign to a group',
    'assignMode': 'Assignment mode',
    'sharedTask': 'One shared task',
    'oneTaskEach': 'One task per person',
    'selectPeople': 'Select people',
    'selectTeam': 'Select a team',
    'assign': 'Assign',
    'assigned': 'Assigned',
    'tasksCreated': '{count} task(s) created',
    'newEvent': 'New event',
    'eventTitle': 'Event title',
    'startsAt': 'Starts',
    'endsAt': 'Ends',
    'allDay': 'All day',
    'location': 'Location',
    'meetingLink': 'Meeting link',
    'attendees': 'Attendees',
    'going': 'Going',
    'maybe': 'Maybe',
    'declined': 'Declined',
    'noEvents': 'Nothing planned for this day',
    'upcoming': 'Upcoming',
    'month': 'Month',
    'day': 'Day',
    'language': 'Language',
    'theme': 'Theme',
    'themeSystem': 'System',
    'themeLight': 'Light',
    'themeDark': 'Dark',
    'notifications': 'Notifications',
    'account': 'Account',
    'role': 'Role',
    'roleMember': 'Member',
    'roleLead': 'Lead',
    'roleAdmin': 'Admin',
    'title': 'Job title',
    'phone': 'Phone',
    'bio': 'Bio',
    'skills': 'Skills',
    'message': 'Message',
    'assignTask': 'Assign a task',
    'searchMembers': 'Search members…',
    'searchTasks': 'Search tasks…',
    'manageMembers': 'Manage members',
    'deactivate': 'Deactivate',
    'activate': 'Activate',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'create': 'Create',
    'close': 'Close',
    'online': 'Online',
    'offline': 'Offline',
    'adminOnly': 'Admins and leads only',
    'welcomeBack': 'Welcome back, {name}',
    'overviewOpenTasks': 'Open tasks',
    'overviewDueThisWeek': 'Due this week',
    'overviewUnread': 'Unread messages',
    'reactionAck': 'Acknowledged',
    'reactionAgree': 'Agree',
    'reactionWatching': 'Watching',
    'reactionBlocker': 'Blocker',
    'reactionDone': 'Done',
    'search': 'Search',
    'searchMessages': 'Search messages…',
    'noResults': 'No results',
    'notificationCenter': 'Notifications',
    'markAllRead': 'Mark all as read',
    'noNotifications': 'You are all caught up',
    'unreadCount': '{count, plural, =0{No unread} =1{1 unread} other{{count} unread}}',
    'mentionSomeone': 'Mention someone',
    'mentionedYou': '{name} mentioned you',
    'assignedYouTask': '{name} assigned you {key}',
    'inChannel': 'in {channel}',
    'resultsCount': '{count, plural, =0{No messages} =1{1 message} other{{count} messages}}',
    'openConversation': 'Open conversation',
    'thread': 'Thread',
    'replyInThread': 'Reply in thread',
    'repliesCount': '{count, plural, =0{No replies} =1{1 reply} other{{count} replies}}',
    'repliedToYou': '{name} replied in your thread',
    'threadReplyHint': 'Reply to the thread',
    'uploading': 'Uploading',
    'uploadFailed': 'Upload failed',
    'retry': 'Retry',
    'fileTooLarge': 'File is larger than {limit}',
    'openFile': 'Open',
    'pushNotifications': 'Push notifications',
    'pushOnThisDevice': 'Receive alerts on this device',
    'pushBlocked': 'Notifications are blocked in your system settings',
    'pushUnsupported': 'Push is not available on this platform',
    'deviceRegistered': 'This device is registered',
    'open': 'Open',
    'errorTitle': 'Something went wrong',
    'errorBody': 'We could not load this. Check your connection and try again.',
    'loading': 'Loading',
    'signedOut': 'You are signed out',
    'mute': 'Mute',
    'unmute': 'Unmute',
    'muted': 'Muted',
    'mutedHint': 'You still see messages, but they will not notify you',
    'seen': 'Seen',
    'seenByCount': '{count, plural, =0{Not seen yet} =1{Seen by 1 member} other{Seen by {count} members}}',
    'sent': 'Sent',
    'addAttachment': 'Add attachment',
    'noAttachments': 'No attachments yet',
    'removeAttachment': 'Remove attachment',
    'edit': 'Edit',
    'edited': 'edited',
    'editMessage': 'Edit message',
    'activityCreated': '{name} created this task',
    'activityStatus': '{name} moved it to {status}',
    'activityProgress': '{name} set progress to {value} percent',
    'activityAssigned': '{name} assigned {people}',
    'activityAttached': '{name} attached {file}',
    'noActivity': 'No activity yet',
  },
  'fr': <String, String>{
    'appName': 'CTG Hub',
    'tagline': 'Discussions, tâches et agenda pour les membres CTG',
    'signIn': 'Se connecter',
    'signOut': 'Se déconnecter',
    'email': 'E-mail',
    'password': 'Mot de passe',
    'demoSignInHint': 'Mode démo — choisissez un membre pour vous connecter',
    'unknownUser': 'Aucun membre CTG trouvé avec cet e-mail',
    'chat': 'Discussion',
    'tasks': 'Tâches',
    'agenda': 'Agenda',
    'members': 'Membres',
    'profile': 'Profil',
    'admin': 'Admin',
    'settings': 'Paramètres',
    'channels': 'Canaux',
    'directMessages': 'Messages privés',
    'newChannel': 'Nouveau canal',
    'newMessage': 'Nouveau message',
    'messageHint': 'Écrivez un message…',
    'send': 'Envoyer',
    'attachImage': 'Image',
    'attachFile': 'Fichier',
    'attachAudio': 'Audio',
    'attachLink': 'Lien',
    'linkTask': 'Lier une tâche',
    'reply': 'Répondre',
    'deleteMessage': 'Supprimer le message',
    'messageDeleted': 'Message supprimé',
    'today': 'Aujourd’hui',
    'yesterday': 'Hier',
    'justNow': 'à l’instant',
    'minutesAgo': '{count} min',
    'hoursAgo': '{count} h',
    'daysAgo': '{count} j',
    'membersCount': '{count, plural, =0{Aucun membre} =1{1 membre} other{{count} membres}}',
    'board': 'Tableau',
    'list': 'Liste',
    'myTasks': 'Mes tâches',
    'allTasks': 'Toutes les tâches',
    'newTask': 'Nouvelle tâche',
    'editTask': 'Modifier la tâche',
    'taskTitle': 'Titre',
    'description': 'Description',
    'status': 'Statut',
    'priority': 'Priorité',
    'type': 'Type',
    'assignees': 'Assigné(e)s',
    'reporter': 'Créée par',
    'team': 'Équipe',
    'labels': 'Étiquettes',
    'progress': 'Progression',
    'dueDate': 'Échéance',
    'estimate': 'Estimation (h)',
    'checklist': 'Check-list',
    'attachments': 'Pièces jointes',
    'comments': 'Commentaires',
    'addComment': 'Ajouter un commentaire…',
    'activity': 'Activité',
    'statusBacklog': 'Backlog',
    'statusTodo': 'À faire',
    'statusInProgress': 'En cours',
    'statusReview': 'Revue',
    'statusDone': 'Terminé',
    'statusBlocked': 'Bloqué',
    'priorityLow': 'Basse',
    'priorityMedium': 'Moyenne',
    'priorityHigh': 'Haute',
    'priorityUrgent': 'Urgente',
    'typeTask': 'Tâche',
    'typeBug': 'Bug',
    'typeFeature': 'Fonctionnalité',
    'overdue': 'En retard',
    'dueSoon': 'Bientôt due',
    'noTasks': 'Aucune tâche ici pour le moment',
    'assignToGroup': 'Assigner à un groupe',
    'assignMode': 'Mode d’assignation',
    'sharedTask': 'Une tâche partagée',
    'oneTaskEach': 'Une tâche par personne',
    'selectPeople': 'Choisir des personnes',
    'selectTeam': 'Choisir une équipe',
    'assign': 'Assigner',
    'assigned': 'Assignée',
    'tasksCreated': '{count} tâche(s) créée(s)',
    'newEvent': 'Nouvel événement',
    'eventTitle': 'Titre de l’événement',
    'startsAt': 'Début',
    'endsAt': 'Fin',
    'allDay': 'Toute la journée',
    'location': 'Lieu',
    'meetingLink': 'Lien de réunion',
    'attendees': 'Participants',
    'going': 'Je participe',
    'maybe': 'Peut-être',
    'declined': 'Refusé',
    'noEvents': 'Rien de prévu ce jour',
    'upcoming': 'À venir',
    'month': 'Mois',
    'day': 'Jour',
    'language': 'Langue',
    'theme': 'Thème',
    'themeSystem': 'Système',
    'themeLight': 'Clair',
    'themeDark': 'Sombre',
    'notifications': 'Notifications',
    'account': 'Compte',
    'role': 'Rôle',
    'roleMember': 'Membre',
    'roleLead': 'Responsable',
    'roleAdmin': 'Administrateur',
    'title': 'Fonction',
    'phone': 'Téléphone',
    'bio': 'Bio',
    'skills': 'Compétences',
    'message': 'Message',
    'assignTask': 'Assigner une tâche',
    'searchMembers': 'Rechercher des membres…',
    'searchTasks': 'Rechercher des tâches…',
    'manageMembers': 'Gérer les membres',
    'deactivate': 'Désactiver',
    'activate': 'Activer',
    'save': 'Enregistrer',
    'cancel': 'Annuler',
    'delete': 'Supprimer',
    'create': 'Créer',
    'close': 'Fermer',
    'online': 'En ligne',
    'offline': 'Hors ligne',
    'adminOnly': 'Réservé aux admins et responsables',
    'welcomeBack': 'Bon retour, {name}',
    'overviewOpenTasks': 'Tâches ouvertes',
    'overviewDueThisWeek': 'Dues cette semaine',
    'overviewUnread': 'Messages non lus',
    'reactionAck': 'Bien reçu',
    'reactionAgree': 'D’accord',
    'reactionWatching': 'Je suis',
    'reactionBlocker': 'Bloquant',
    'reactionDone': 'Terminé',
    'search': 'Rechercher',
    'searchMessages': 'Rechercher des messages…',
    'noResults': 'Aucun résultat',
    'notificationCenter': 'Notifications',
    'markAllRead': 'Tout marquer comme lu',
    'noNotifications': 'Vous êtes à jour',
    'unreadCount': '{count, plural, =0{Aucun non lu} =1{1 non lu} other{{count} non lus}}',
    'mentionSomeone': 'Mentionner quelqu’un',
    'mentionedYou': '{name} vous a mentionné',
    'assignedYouTask': '{name} vous a assigné {key}',
    'inChannel': 'dans {channel}',
    'resultsCount': '{count, plural, =0{Aucun message} =1{1 message} other{{count} messages}}',
    'openConversation': 'Ouvrir la conversation',
    'thread': 'Fil de discussion',
    'replyInThread': 'Répondre dans le fil',
    'repliesCount': '{count, plural, =0{Aucune réponse} =1{1 réponse} other{{count} réponses}}',
    'repliedToYou': '{name} a répondu dans votre fil',
    'threadReplyHint': 'Répondre au fil',
    'uploading': 'Téléversement',
    'uploadFailed': 'Échec du téléversement',
    'retry': 'Réessayer',
    'fileTooLarge': 'Le fichier dépasse {limit}',
    'openFile': 'Ouvrir',
    'pushNotifications': 'Notifications push',
    'pushOnThisDevice': 'Recevoir les alertes sur cet appareil',
    'pushBlocked': 'Les notifications sont bloquées dans les réglages du système',
    'pushUnsupported': 'Le push n\'est pas disponible sur cette plateforme',
    'deviceRegistered': 'Cet appareil est enregistré',
    'open': 'Ouvrir',
    'errorTitle': 'Une erreur est survenue',
    'errorBody': 'Chargement impossible. Vérifiez votre connexion et réessayez.',
    'loading': 'Chargement',
    'signedOut': 'Vous êtes déconnecté',
    'mute': 'Mettre en sourdine',
    'unmute': 'Réactiver les alertes',
    'muted': 'En sourdine',
    'mutedHint': 'Vous voyez les messages, mais sans notification',
    'seen': 'Vu',
    'seenByCount': '{count, plural, =0{Pas encore vu} =1{Vu par 1 membre} other{Vu par {count} membres}}',
    'sent': 'Envoyé',
    'addAttachment': 'Ajouter une pièce jointe',
    'noAttachments': 'Aucune pièce jointe',
    'removeAttachment': 'Retirer la pièce jointe',
    'edit': 'Modifier',
    'edited': 'modifié',
    'editMessage': 'Modifier le message',
    'activityCreated': '{name} a créé cette tâche',
    'activityStatus': '{name} l\'a déplacée vers {status}',
    'activityProgress': '{name} a mis l\'avancement à {value} pour cent',
    'activityAssigned': '{name} a assigné {people}',
    'activityAttached': '{name} a joint {file}',
    'noActivity': 'Aucune activité',
  },
  'ar': <String, String>{
    'appName': 'مركز CTG',
    'tagline': 'محادثات ومهام وأجندة لأعضاء CTG',
    'signIn': 'تسجيل الدخول',
    'signOut': 'تسجيل الخروج',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'demoSignInHint': 'وضع العرض — اختر عضوًا لتسجيل الدخول',
    'unknownUser': 'لا يوجد عضو CTG بهذا البريد الإلكتروني',
    'chat': 'المحادثات',
    'tasks': 'المهام',
    'agenda': 'الأجندة',
    'members': 'الأعضاء',
    'profile': 'الملف الشخصي',
    'admin': 'الإدارة',
    'settings': 'الإعدادات',
    'channels': 'القنوات',
    'directMessages': 'الرسائل الخاصة',
    'newChannel': 'قناة جديدة',
    'newMessage': 'رسالة جديدة',
    'messageHint': 'اكتب رسالة…',
    'send': 'إرسال',
    'attachImage': 'صورة',
    'attachFile': 'ملف',
    'attachAudio': 'صوت',
    'attachLink': 'رابط',
    'linkTask': 'ربط مهمة',
    'reply': 'رد',
    'deleteMessage': 'حذف الرسالة',
    'messageDeleted': 'تم حذف الرسالة',
    'today': 'اليوم',
    'yesterday': 'أمس',
    'justNow': 'الآن',
    'minutesAgo': '{count} د',
    'hoursAgo': '{count} س',
    'daysAgo': '{count} ي',
    'membersCount': '{count, plural, =0{لا أعضاء} =1{عضو واحد} =2{عضوان} few{{count} أعضاء} other{{count} عضوًا}}',
    'board': 'اللوحة',
    'list': 'قائمة',
    'myTasks': 'مهامي',
    'allTasks': 'كل المهام',
    'newTask': 'مهمة جديدة',
    'editTask': 'تعديل المهمة',
    'taskTitle': 'العنوان',
    'description': 'الوصف',
    'status': 'الحالة',
    'priority': 'الأولوية',
    'type': 'النوع',
    'assignees': 'المكلفون',
    'reporter': 'أنشأها',
    'team': 'الفريق',
    'labels': 'الوسوم',
    'progress': 'التقدم',
    'dueDate': 'تاريخ الاستحقاق',
    'estimate': 'التقدير (ساعة)',
    'checklist': 'قائمة التحقق',
    'attachments': 'المرفقات',
    'comments': 'التعليقات',
    'addComment': 'أضف تعليقًا…',
    'activity': 'النشاط',
    'statusBacklog': 'قائمة الانتظار',
    'statusTodo': 'للتنفيذ',
    'statusInProgress': 'قيد التنفيذ',
    'statusReview': 'قيد المراجعة',
    'statusDone': 'منجزة',
    'statusBlocked': 'متوقفة',
    'priorityLow': 'منخفضة',
    'priorityMedium': 'متوسطة',
    'priorityHigh': 'عالية',
    'priorityUrgent': 'عاجلة',
    'typeTask': 'مهمة',
    'typeBug': 'خلل',
    'typeFeature': 'ميزة',
    'overdue': 'متأخرة',
    'dueSoon': 'قريبة الاستحقاق',
    'noTasks': 'لا توجد مهام هنا بعد',
    'assignToGroup': 'إسناد إلى مجموعة',
    'assignMode': 'طريقة الإسناد',
    'sharedTask': 'مهمة مشتركة واحدة',
    'oneTaskEach': 'مهمة لكل شخص',
    'selectPeople': 'اختر أشخاصًا',
    'selectTeam': 'اختر فريقًا',
    'assign': 'إسناد',
    'assigned': 'تم الإسناد',
    'tasksCreated': 'تم إنشاء {count} مهمة',
    'newEvent': 'حدث جديد',
    'eventTitle': 'عنوان الحدث',
    'startsAt': 'يبدأ',
    'endsAt': 'ينتهي',
    'allDay': 'طوال اليوم',
    'location': 'المكان',
    'meetingLink': 'رابط الاجتماع',
    'attendees': 'الحاضرون',
    'going': 'سأحضر',
    'maybe': 'ربما',
    'declined': 'اعتذار',
    'noEvents': 'لا شيء مخطط لهذا اليوم',
    'upcoming': 'القادم',
    'month': 'شهر',
    'day': 'يوم',
    'language': 'اللغة',
    'theme': 'المظهر',
    'themeSystem': 'النظام',
    'themeLight': 'فاتح',
    'themeDark': 'داكن',
    'notifications': 'الإشعارات',
    'account': 'الحساب',
    'role': 'الدور',
    'roleMember': 'عضو',
    'roleLead': 'مسؤول فريق',
    'roleAdmin': 'مدير',
    'title': 'المسمى الوظيفي',
    'phone': 'الهاتف',
    'bio': 'نبذة',
    'skills': 'المهارات',
    'message': 'مراسلة',
    'assignTask': 'إسناد مهمة',
    'searchMembers': 'ابحث عن أعضاء…',
    'searchTasks': 'ابحث عن مهام…',
    'manageMembers': 'إدارة الأعضاء',
    'deactivate': 'تعطيل',
    'activate': 'تفعيل',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'delete': 'حذف',
    'create': 'إنشاء',
    'close': 'إغلاق',
    'online': 'متصل',
    'offline': 'غير متصل',
    'adminOnly': 'للمديرين ومسؤولي الفرق فقط',
    'welcomeBack': 'مرحبًا من جديد، {name}',
    'overviewOpenTasks': 'مهام مفتوحة',
    'overviewDueThisWeek': 'مستحقة هذا الأسبوع',
    'overviewUnread': 'رسائل غير مقروءة',
    'reactionAck': 'تم الاطلاع',
    'reactionAgree': 'أوافق',
    'reactionWatching': 'أتابع',
    'reactionBlocker': 'معيق',
    'reactionDone': 'منجز',
    'search': 'بحث',
    'searchMessages': 'ابحث في الرسائل…',
    'noResults': 'لا توجد نتائج',
    'notificationCenter': 'الإشعارات',
    'markAllRead': 'تعليم الكل كمقروء',
    'noNotifications': 'لا جديد لديك',
    'unreadCount': '{count, plural, =0{لا رسائل غير مقروءة} =1{رسالة واحدة غير مقروءة} =2{رسالتان غير مقروءتين} few{{count} رسائل غير مقروءة} other{{count} رسالة غير مقروءة}}',
    'mentionSomeone': 'أشر إلى شخص',
    'mentionedYou': 'أشار إليك {name}',
    'assignedYouTask': 'أسند إليك {name} المهمة {key}',
    'inChannel': 'في {channel}',
    'resultsCount': '{count, plural, =0{لا رسائل} =1{رسالة واحدة} =2{رسالتان} few{{count} رسائل} other{{count} رسالة}}',
    'openConversation': 'فتح المحادثة',
    'thread': 'سلسلة الردود',
    'replyInThread': 'الرد في السلسلة',
    'repliesCount': '{count, plural, =0{لا ردود} =1{رد واحد} =2{ردان} few{{count} ردود} other{{count} رد}}',
    'repliedToYou': 'رد {name} في سلسلتك',
    'threadReplyHint': 'اكتب ردا على السلسلة',
    'uploading': 'جارٍ الرفع',
    'uploadFailed': 'فشل الرفع',
    'retry': 'إعادة المحاولة',
    'fileTooLarge': 'حجم الملف أكبر من {limit}',
    'openFile': 'فتح',
    'pushNotifications': 'الإشعارات الفورية',
    'pushOnThisDevice': 'استقبال التنبيهات على هذا الجهاز',
    'pushBlocked': 'الإشعارات محظورة في إعدادات النظام',
    'pushUnsupported': 'الإشعارات الفورية غير متاحة على هذه المنصة',
    'deviceRegistered': 'تم تسجيل هذا الجهاز',
    'open': 'فتح',
    'errorTitle': 'حدث خطأ ما',
    'errorBody': 'تعذر التحميل. تحقق من الاتصال وحاول مرة أخرى.',
    'loading': 'جارٍ التحميل',
    'signedOut': 'تم تسجيل خروجك',
    'mute': 'كتم',
    'unmute': 'إلغاء الكتم',
    'muted': 'مكتوم',
    'mutedHint': 'ستظل ترى الرسائل دون تلقي إشعارات',
    'seen': 'تمت المشاهدة',
    'seenByCount': '{count, plural, =0{لم يُشاهد بعد} =1{شاهده عضو واحد} =2{شاهده عضوان} few{شاهده {count} أعضاء} other{شاهده {count} عضوا}}',
    'sent': 'أُرسلت',
    'addAttachment': 'إضافة مرفق',
    'noAttachments': 'لا توجد مرفقات',
    'removeAttachment': 'إزالة المرفق',
    'edit': 'تعديل',
    'edited': 'مُعدَّل',
    'editMessage': 'تعديل الرسالة',
    'activityCreated': 'أنشأ {name} هذه المهمة',
    'activityStatus': 'نقلها {name} إلى {status}',
    'activityProgress': 'ضبط {name} التقدم على {value} بالمئة',
    'activityAssigned': 'أسندها {name} إلى {people}',
    'activityAttached': 'أرفق {name} الملف {file}',
    'noActivity': 'لا يوجد نشاط بعد',
  },
};
