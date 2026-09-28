import * as admin from 'firebase-admin';
import { Locale, normalizeLocale } from './i18n';

export interface Recipient {
  uid: string;
  locale: Locale;
  tokens: string[];
  muted: string[];
}

/** Loads the delivery preferences of a set of members in one round trip. */
export async function loadRecipients(uids: string[]): Promise<Recipient[]> {
  const unique = [...new Set(uids)].filter(Boolean);
  if (unique.length === 0) return [];

  const db = admin.firestore();
  const chunks: string[][] = [];
  for (let i = 0; i < unique.length; i += 10) chunks.push(unique.slice(i, i + 10));

  const results: Recipient[] = [];
  for (const chunk of chunks) {
    const snap = await db
      .collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
      .get();
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.active === false) continue;
      results.push({
        uid: doc.id,
        locale: normalizeLocale(data.locale),
        tokens: (data.fcmTokens as string[] | undefined) ?? [],
        muted: (data.mutedChannels as string[] | undefined) ?? [],
      });
    }
  }
  return results;
}

export interface Payload {
  title: string;
  body: string;
  route: string;
  kind: string;
}

/**
 * Writes an in-app notification and, when the member has registered devices,
 * sends the same copy over FCM. Invalid tokens are pruned.
 */
export async function deliver(recipient: Recipient, payload: Payload): Promise<void> {
  const db = admin.firestore();
  await db.collection('notifications').doc(recipient.uid).collection('items').add({
    kind: payload.kind,
    title: payload.title,
    body: payload.body,
    route: payload.route,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (recipient.tokens.length === 0) return;

  const response = await admin.messaging().sendEachForMulticast({
    tokens: recipient.tokens,
    notification: { title: payload.title, body: payload.body },
    data: { route: payload.route, kind: payload.kind },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });

  const stale: string[] = [];
  response.responses.forEach((result, index) => {
    const code = result.error?.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      stale.push(recipient.tokens[index]);
    }
  });
  if (stale.length > 0) {
    await db
      .collection('users')
      .doc(recipient.uid)
      .update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(...stale) });
  }
}

export async function fanOut(
  recipients: Recipient[],
  build: (recipient: Recipient) => Payload
): Promise<void> {
  await Promise.all(recipients.map((recipient) => deliver(recipient, build(recipient))));
}
