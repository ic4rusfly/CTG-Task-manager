import 'package:ctg_hub/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every supported locale resolves the same keys', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final t = AppLocalizations(locale.languageCode);
      expect(t.tasks, isNotEmpty);
      expect(t.agenda, isNotEmpty);
      expect(t.assignToGroup, isNotEmpty);
      expect(t.reactionAck, isNotEmpty);
    }
  });

  test('placeholders are substituted', () {
    final t = AppLocalizations('en');
    expect(t.welcomeBack('Omar'), contains('Omar'));
    expect(t.minutesAgo(12), contains('12'));
    expect(t.tasksCreated(3), contains('3'));
  });

  test('plural categories differ per locale', () {
    expect(AppLocalizations('en').membersCount(1), '1 member');
    expect(AppLocalizations('en').membersCount(4), '4 members');
    expect(AppLocalizations('fr').membersCount(0), 'Aucun membre');
    expect(AppLocalizations('ar').membersCount(2), 'عضوان');
  });

  test('French and Arabic are actually translated, not English copies', () {
    final en = AppLocalizations('en');
    final fr = AppLocalizations('fr');
    final ar = AppLocalizations('ar');
    expect(fr.tasks, isNot(en.tasks));
    expect(ar.tasks, isNot(en.tasks));
  });
}
