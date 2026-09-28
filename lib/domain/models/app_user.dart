import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.title = '',
    this.teamId,
    this.phone = '',
    this.bio = '',
    this.skills = const [],
    this.role = UserRole.member,
    this.locale = 'en',
    this.online = false,
    this.lastSeenAt,
    this.active = true,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String title;
  final String? teamId;
  final String phone;
  final String bio;
  final List<String> skills;
  final UserRole role;
  final String locale;
  final bool online;
  final DateTime? lastSeenAt;
  final bool active;

  bool get isAdmin => role == UserRole.admin;
  bool get canAssign => role == UserRole.admin || role == UserRole.lead;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.firstLetter();
    return '${parts.first.firstLetter()}${parts[1].firstLetter()}';
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? title,
    String? teamId,
    String? phone,
    String? bio,
    List<String>? skills,
    UserRole? role,
    String? locale,
    bool? online,
    DateTime? lastSeenAt,
    bool? active,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      title: title ?? this.title,
      teamId: teamId ?? this.teamId,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      role: role ?? this.role,
      locale: locale ?? this.locale,
      online: online ?? this.online,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'title': title,
        'teamId': teamId,
        'phone': phone,
        'bio': bio,
        'skills': skills,
        'role': role.name,
        'locale': locale,
        'online': online,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'active': active,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        displayName: map['displayName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        title: map['title'] as String? ?? '',
        teamId: map['teamId'] as String?,
        phone: map['phone'] as String? ?? '',
        bio: map['bio'] as String? ?? '',
        skills: (map['skills'] as List?)?.cast<String>() ?? const [],
        role: userRoleFrom(map['role'] as String?),
        locale: map['locale'] as String? ?? 'en',
        online: map['online'] as bool? ?? false,
        lastSeenAt: DateTime.tryParse(map['lastSeenAt'] as String? ?? ''),
        active: map['active'] as bool? ?? true,
      );
}

extension on String {
  String firstLetter() => isEmpty ? '?' : substring(0, 1).toUpperCase();
}
