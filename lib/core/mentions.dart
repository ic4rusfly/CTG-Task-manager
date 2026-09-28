import '../domain/models/app_user.dart';

/// Matches "@" followed by a word (letters in any script, digits, dot, dash).
final mentionPattern = RegExp(r'@([\p{L}\p{N}._-]+)', unicode: true);

/// Resolves the "@name" tokens of [text] to member ids.
///
/// A token matches when it equals a member's first name, their handle (the
/// part of the email before the "@") or their full name without spaces —
/// case-insensitively, which also covers Arabic and French names.
List<String> parseMentions(String text, List<AppUser> users) {
  final ids = <String>{};
  for (final match in mentionPattern.allMatches(text)) {
    final token = match.group(1)!.toLowerCase();
    for (final user in users) {
      final first = user.displayName.split(RegExp(r'\s+')).first.toLowerCase();
      final handle = user.email.split('@').first.toLowerCase();
      final compact = user.displayName.replaceAll(' ', '').toLowerCase();
      if (token == first || token == handle || token == compact) {
        ids.add(user.id);
        break;
      }
    }
  }
  return ids.toList();
}

/// Splits [text] into plain and mention segments so the UI can style them.
class TextSegment {
  const TextSegment(this.text, {this.isMention = false, this.userId});

  final String text;
  final bool isMention;
  final String? userId;
}

List<TextSegment> splitMentions(String text, List<AppUser> users) {
  final segments = <TextSegment>[];
  var cursor = 0;
  for (final match in mentionPattern.allMatches(text)) {
    final token = match.group(1)!.toLowerCase();
    final user = users.where((u) {
      final first = u.displayName.split(RegExp(r'\s+')).first.toLowerCase();
      final handle = u.email.split('@').first.toLowerCase();
      return token == first || token == handle;
    }).toList();
    if (user.isEmpty) continue;
    if (match.start > cursor) {
      segments.add(TextSegment(text.substring(cursor, match.start)));
    }
    segments.add(TextSegment(match.group(0)!, isMention: true, userId: user.first.id));
    cursor = match.end;
  }
  if (cursor < text.length) segments.add(TextSegment(text.substring(cursor)));
  return segments.isEmpty ? [TextSegment(text)] : segments;
}
