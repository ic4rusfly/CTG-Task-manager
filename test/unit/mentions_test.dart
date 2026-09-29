import 'package:ctg_hub/core/mentions.dart';
import 'package:ctg_hub/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

const users = [
  AppUser(id: 'u2', displayName: 'Omar El Idrissi', email: 'omar@ctg.ma'),
  AppUser(id: 'u3', displayName: 'Salma Ait Taleb', email: 'salma@ctg.ma'),
  AppUser(id: 'u5', displayName: 'Nour Haddad', email: 'nour@ctg.ma'),
];

void main() {
  group('parseMentions', () {
    test('matches a first name', () {
      expect(parseMentions('can you check this @Omar', users), ['u2']);
    });

    test('matches the email handle and is case insensitive', () {
      expect(parseMentions('@SALMA please review', users), ['u3']);
    });

    test('collects several mentions without duplicates', () {
      final ids = parseMentions('@Omar @Nour and again @omar', users);
      expect(ids, hasLength(2));
      expect(ids, containsAll(<String>['u2', 'u5']));
    });

    test('ignores unknown handles and bare emails', () {
      expect(parseMentions('write to contact@ctg.ma or @nobody', users), isEmpty);
    });

    test('returns nothing when there is no mention', () {
      expect(parseMentions('standup at 10', users), isEmpty);
    });
  });

  group('splitMentions', () {
    test('splits text into plain and mention segments', () {
      final segments = splitMentions('hi @Omar, see this', users);
      expect(segments.map((s) => s.isMention), [false, true, false]);
      expect(segments[1].text, '@Omar');
      expect(segments[1].userId, 'u2');
    });

    test('keeps plain text as a single segment', () {
      final segments = splitMentions('no mentions here', users);
      expect(segments, hasLength(1));
      expect(segments.single.isMention, isFalse);
    });
  });
}
