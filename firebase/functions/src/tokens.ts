/**
 * Search tokenisation - the twin of `lib/core/search_tokens.dart`.
 *
 * Messages carry a `keywords` array so the client can search with a single
 * indexed collection-group query instead of downloading conversations.
 */
export const MAX_KEYWORDS = 60;

/** Anything that is not a letter or a digit separates two words. */
const SEPARATORS = /[^\p{L}\p{N}]+/u;

export function searchTokens(text: string, extra: string[] = []): string[] {
  const seen = new Set<string>();
  for (const source of [text, ...extra]) {
    for (const raw of (source ?? '').toLowerCase().split(SEPARATORS)) {
      if (raw.length < 2) continue;
      seen.add(raw);
      if (seen.size >= MAX_KEYWORDS) return [...seen];
    }
  }
  return [...seen];
}

/** True when the stored keywords already match the text. */
export function sameTokens(a: string[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  const set = new Set(a);
  return b.every((token) => set.has(token));
}
