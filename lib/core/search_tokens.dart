/// Tokenisation shared by the client and the Cloud Functions.
///
/// Messages carry a `keywords` array so search is a single indexed Firestore
/// query instead of a scan. The same rules must hold on both sides, so this
/// file and `firebase/functions/src/tokens.ts` are deliberate twins.
library;

/// Anything that is not a letter or a digit separates two words, which keeps
/// Arabic, French accents and hyphenated names working.
final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Longest keyword list stored per message, to bound the document size.
const int maxKeywords = 60;

/// Lowercase, de-duplicated words of [text] plus any [extra] strings
/// (attachment names, for example), each at least two characters long.
List<String> searchTokens(String text, {Iterable<String> extra = const []}) {
  final seen = <String>{};
  for (final source in [text, ...extra]) {
    for (final raw in source.toLowerCase().split(_separators)) {
      if (raw.length < 2) continue;
      seen.add(raw);
      if (seen.length >= maxKeywords) return seen.toList();
    }
  }
  return seen.toList();
}

/// The token a Firestore query should filter on: the longest word of the
/// query, which is the most selective one. Null when the query is too short.
String? queryToken(String query) {
  final tokens = searchTokens(query);
  if (tokens.isEmpty) return null;
  tokens.sort((a, b) => b.length.compareTo(a.length));
  return tokens.first;
}

/// Client-side check that the whole query really appears in the message, used
/// after the indexed query narrows the candidates down.
bool matchesQuery(String haystack, String query) =>
    haystack.toLowerCase().contains(query.trim().toLowerCase());
