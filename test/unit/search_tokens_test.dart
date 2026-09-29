import 'package:ctg_hub/core/search_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('search tokens', () {
    test('splits on punctuation and lowercases', () {
      expect(
        searchTokens('Agenda for CTG-Day, v2!'),
        containsAll(['agenda', 'for', 'ctg', 'day', 'v2']),
      );
    });

    test('keeps Arabic and accented French words intact', () {
      final tokens = searchTokens('Réunion à 15h avec مرحبا بالعالم');
      expect(tokens, contains('réunion'));
      expect(tokens, contains('15h'));
      expect(tokens, contains('مرحبا'));
      expect(tokens, contains('بالعالم'));
    });

    test('drops one-letter noise and duplicates', () {
      final tokens = searchTokens('a a bb bb ccc');
      expect(tokens, ['bb', 'ccc']);
    });

    test('indexes attachment names too', () {
      expect(
        searchTokens('here it is', extra: ['venue-contract.pdf']),
        containsAll(['venue', 'contract', 'pdf']),
      );
    });

    test('never stores more than the cap', () {
      final long = List.generate(200, (i) => 'word$i').join(' ');
      expect(searchTokens(long).length, lessThanOrEqualTo(maxKeywords));
    });

    test('the query token is the most selective word', () {
      expect(queryToken('the onboarding plan'), 'onboarding');
      expect(queryToken('a'), isNull);
    });

    test('the full phrase is re-checked client side', () {
      expect(matchesQuery('Assign the onboarding tasks', 'onboarding tasks'), isTrue);
      expect(matchesQuery('Assign the onboarding tasks', 'onboarding plan'), isFalse);
    });
  });
}
