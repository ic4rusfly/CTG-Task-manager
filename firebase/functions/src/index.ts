/**
 * CTG Hub Cloud Functions.
 *
 *  onUserCreate          new member -> custom claims + join #general
 *  onMessageCreate       chat message -> FCM fan-out in each recipient's language
 *  onTaskWrite           assignment / status change -> notifications + activity log
 *  dueSoonScheduler      hourly cron -> "due within 24h" reminders
 *  onEventCreate         agenda invite -> notifications
 *  assignTaskGroup       callable -> assign one task to many, or clone per person
 *  registerDevice        callable -> store an FCM token for the signed-in member
 *  unregisterDevice      callable -> drop an FCM token on sign-out
 *
 * Region: europe-west1 (closest to Morocco).
 */
import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as functions from 'firebase-functions/v1';
import { formatDate, normalizeLocale, statusLabel, t } from './i18n';
import { deliver, fanOut, loadRecipients } from './notify';

admin.initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });

const db = admin.firestore();
const GENERAL_CHANNEL = 'c_general';

const displayName = async (uid: string): Promise<string> => {
  const snap = await db.collection('users').doc(uid).get();
  return (snap.get('displayName') as string | undefined) ?? 'CTG';
};

// ---------------------------------------------------------------------------
// New member onboarding
// ---------------------------------------------------------------------------
export const onUserCreate = functions
  .region('europe-west1')
  .auth.user()
  .onCreate(async (user) => {
    const ref = db.collection('users').doc(user.uid);
    const existing = await ref.get();

    // Invite-only: an admin may have pre-created the member record.
    const role = (existing.get('role') as string | undefined) ?? 'member';
    await ref.set(
      {
        displayName: existing.get('displayName') ?? user.displayName ?? user.email?.split('@')[0] ?? 'CTG member',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? null,
        role,
        locale: existing.get('locale') ?? 'en',
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await admin.auth().setCustomUserClaims(user.uid, {
      admin: role === 'admin',
      lead: role === 'lead',
    });

    await db
      .collection('channels')
      .doc(GENERAL_CHANNEL)
      .set(
        { memberIds: admin.firestore.FieldValue.arrayUnion(user.uid) },
        { merge: true }
      );
  });

/** Keeps custom claims in sync when an admin changes somebody's role. */
export const onUserRoleChange = onDocumentWritten('users/{uid}', async (event) => {
  const before = event.data?.before.get('role') as string | undefined;
  const after = event.data?.after.get('role') as string | undefined;
  if (!after || before === after) return;
  await admin.auth().setCustomUserClaims(event.params.uid, {
    admin: after === 'admin',
    lead: after === 'lead',
  });
});

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------
export const onMessageCreate = onDocumentCreated(
  'channels/{channelId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const channelId = event.params.channelId;
    const channelSnap = await db.collection('channels').doc(channelId).get();
    if (!channelSnap.exists) return;

    const memberIds = (channelSnap.get('memberIds') as string[] | undefined) ?? [];
    const isDm = channelSnap.get('type') === 'dm';
    const channelName = isDm ? '' : `#${channelSnap.get('name') ?? ''}`;
    const senderId = message.senderId as string;
    const actor = await displayName(senderId);

    const mentions = (message.mentions as string[] | undefined) ?? [];
    const replyToId = message.replyToId as string | undefined;

    // A thread reply only notifies the people involved in that thread, not the
    // whole channel: the root author, plus anyone mentioned in the reply.
    if (replyToId) {
      const rootSnap = await db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(replyToId)
        .get();
      const rootAuthor = rootSnap.get('senderId') as string | undefined;
      const threadTargets = [...new Set([...(rootAuthor ? [rootAuthor] : []), ...mentions])]
        .filter((uid) => uid !== senderId && memberIds.includes(uid));
      if (threadTargets.length === 0) return;
      const threadRecipients = await loadRecipients(threadTargets);
      await fanOut(threadRecipients, (recipient) => {
        const locale = recipient.locale;
        const text =
          (message.text as string | undefined)?.trim() || t('attachmentFallback', locale);
        return {
          kind: mentions.includes(recipient.uid) ? 'mention' : 'message',
          title: mentions.includes(recipient.uid)
            ? t('mentionTitle', locale)
            : t('threadReplyTitle', locale, { actor }),
          body: text,
          route: `/chat/${channelId}/thread/${replyToId}`,
        };
      });
      return;
    }

    const targets = memberIds.filter((uid) => uid !== senderId);
    const recipients = (await loadRecipients(targets)).filter(
      (recipient) => mentions.includes(recipient.uid) || !recipient.muted.includes(channelId)
    );

    await fanOut(recipients, (recipient) => {
      const locale = recipient.locale;
      const text =
        (message.text as string | undefined)?.trim() ||
        t('attachmentFallback', locale);
      return {
        kind: mentions.includes(recipient.uid) ? 'mention' : 'message',
        title: mentions.includes(recipient.uid) ? t('mentionTitle', locale) : actor,
        body: isDm
          ? t('dmBody', locale, { actor, text })
          : t('messageBody', locale, { actor, channel: channelName, text }),
        route: `/chat/${channelId}`,
      };
    });
  }
);

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------
export const onTaskWrite = onDocumentWritten('tasks/{taskId}', async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  if (!after?.exists) return;

  const taskId = event.params.taskId;
  const key = (after.get('key') as string | undefined) ?? taskId;
  const title = (after.get('title') as string | undefined) ?? '';
  const assignees = (after.get('assigneeIds') as string[] | undefined) ?? [];
  const previousAssignees = (before?.get('assigneeIds') as string[] | undefined) ?? [];
  const actorId =
    (after.get('lastActorId') as string | undefined) ??
    (after.get('reporterId') as string | undefined) ??
    '';
  const actor = actorId ? await displayName(actorId) : 'CTG';

  // 1. Newly assigned members
  const added = assignees.filter((uid) => !previousAssignees.includes(uid) && uid !== actorId);
  if (added.length > 0) {
    const recipients = await loadRecipients(added);
    await fanOut(recipients, (recipient) => ({
      kind: 'taskAssigned',
      title: t('taskAssignedTitle', recipient.locale),
      body: t('taskAssignedBody', recipient.locale, { actor, key, title }),
      route: `/tasks/${taskId}`,
    }));
  }

  // 2. Status change -> tell the watchers and the reporter
  const beforeStatus = before?.get('status') as string | undefined;
  const afterStatus = after.get('status') as string | undefined;
  if (before?.exists && afterStatus && beforeStatus !== afterStatus) {
    const watchers = [
      ...((after.get('watcherIds') as string[] | undefined) ?? []),
      (after.get('reporterId') as string | undefined) ?? '',
      ...assignees,
    ].filter((uid) => uid && uid !== actorId);

    const recipients = await loadRecipients(watchers);
    await fanOut(recipients, (recipient) => ({
      kind: 'taskStatus',
      title: t('taskStatusTitle', recipient.locale),
      body: t('taskStatusBody', recipient.locale, {
        key,
        status: statusLabel(afterStatus, recipient.locale),
      }),
      route: `/tasks/${taskId}`,
    }));

    await after.ref.collection('activity').add({
      actorId,
      kind: 'status',
      from: beforeStatus ?? null,
      to: afterStatus,
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // 3. Progress trail
  const beforeProgress = (before?.get('progress') as number | undefined) ?? 0;
  const afterProgress = (after.get('progress') as number | undefined) ?? 0;
  if (before?.exists && beforeProgress !== afterProgress) {
    await after.ref.collection('activity').add({
      actorId,
      kind: 'progress',
      from: beforeProgress,
      to: afterProgress,
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});

/** Hourly reminder for everything due in the next 24 hours. */
export const dueSoonScheduler = onSchedule('every 60 minutes', async () => {
  const now = new Date();
  const horizon = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  const snap = await db
    .collection('tasks')
    .where('dueAt', '>=', now.toISOString())
    .where('dueAt', '<=', horizon.toISOString())
    .get();

  for (const doc of snap.docs) {
    if (doc.get('status') === 'done') continue;
    if (doc.get('dueSoonNotifiedAt')) continue;

    const key = (doc.get('key') as string | undefined) ?? doc.id;
    const title = (doc.get('title') as string | undefined) ?? '';
    const recipients = await loadRecipients((doc.get('assigneeIds') as string[] | undefined) ?? []);

    await fanOut(recipients, (recipient) => ({
      kind: 'dueSoon',
      title: t('taskDueSoonTitle', recipient.locale),
      body: t('taskDueSoonBody', recipient.locale, { key, title }),
      route: `/tasks/${doc.id}`,
    }));

    await doc.ref.update({ dueSoonNotifiedAt: admin.firestore.FieldValue.serverTimestamp() });
  }
});

// ---------------------------------------------------------------------------
// Agenda
// ---------------------------------------------------------------------------
export const onEventCreate = onDocumentCreated('events/{eventId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const createdBy = data.createdBy as string;
  const actor = await displayName(createdBy);
  const title = (data.title as string | undefined) ?? '';
  const startAt = new Date((data.startAt as string | undefined) ?? Date.now());
  const attendees = ((data.attendeeIds as string[] | undefined) ?? []).filter(
    (uid) => uid !== createdBy
  );

  const recipients = await loadRecipients(attendees);
  await fanOut(recipients, (recipient) => ({
    kind: 'eventInvite',
    title: t('eventInviteTitle', recipient.locale),
    body: t('eventInviteBody', recipient.locale, {
      actor,
      title,
      date: formatDate(startAt, recipient.locale),
    }),
    route: `/agenda/${event.params.eventId}`,
  }));
});

// ---------------------------------------------------------------------------
// Group assignment (callable)
// ---------------------------------------------------------------------------
interface AssignRequest {
  title: string;
  description?: string;
  assigneeIds: string[];
  teamId?: string | null;
  priority?: string;
  type?: string;
  status?: string;
  dueAt?: string | null;
  estimateHours?: number | null;
  labels?: string[];
  clonePerAssignee?: boolean;
}

export const assignTaskGroup = onCall<AssignRequest>(async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Sign in first.');

  const claims = auth.token as Record<string, unknown>;
  const callerSnap = await db.collection('users').doc(auth.uid).get();
  const role = callerSnap.get('role') as string | undefined;
  const allowed = claims.admin === true || claims.lead === true || role === 'admin' || role === 'lead';
  if (!allowed) throw new HttpsError('permission-denied', 'Admins and leads only.');

  const payload = request.data;
  const people = [...new Set(payload.assigneeIds ?? [])].filter(Boolean);
  if (!payload.title?.trim()) throw new HttpsError('invalid-argument', 'A title is required.');
  if (people.length === 0) throw new HttpsError('invalid-argument', 'Pick at least one assignee.');

  const counterRef = db.collection('counters').doc('tasks');
  const groupId = db.collection('tasks').doc().id;
  const clone = payload.clonePerAssignee === true;
  const batches = clone ? people.map((uid) => [uid]) : [people];

  const created = await db.runTransaction(async (tx) => {
    const counter = await tx.get(counterRef);
    let next = ((counter.get('value') as number | undefined) ?? 100) + 1;
    const ids: string[] = [];

    for (const group of batches) {
      const ref = db.collection('tasks').doc();
      tx.set(ref, {
        key: `CTG-${next}`,
        projectId: 'ctg',
        title: payload.title.trim(),
        description: payload.description ?? '',
        status: payload.status ?? 'todo',
        priority: payload.priority ?? 'medium',
        type: payload.type ?? 'task',
        assigneeIds: group,
        reporterId: auth.uid,
        lastActorId: auth.uid,
        teamId: payload.teamId ?? null,
        labels: payload.labels ?? [],
        progress: 0,
        dueAt: payload.dueAt ?? null,
        estimateHours: payload.estimateHours ?? null,
        checklist: [],
        attachments: [],
        watcherIds: [auth.uid],
        groupAssignmentId: clone || people.length > 1 ? groupId : null,
        createdAt: new Date().toISOString(),
      });
      ids.push(ref.id);
      next += 1;
    }

    tx.set(counterRef, { value: next - 1 }, { merge: true });
    return ids;
  });

  return { taskIds: created, groupAssignmentId: groupId, count: created.length };
});

/** Lets a member register / refresh the FCM token of the current device. */
export const registerDevice = onCall<{ token: string }>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const token = request.data?.token;
  if (!token) throw new HttpsError('invalid-argument', 'Missing token.');

  await db
    .collection('users')
    .doc(request.auth.uid)
    .set({ fcmTokens: admin.firestore.FieldValue.arrayUnion(token) }, { merge: true });
  return { ok: true };
});

/** Drops a device token, e.g. when a member signs out on that device. */
export const unregisterDevice = onCall<{ token: string }>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const token = request.data?.token;
  if (!token) throw new HttpsError('invalid-argument', 'Missing token.');

  await db
    .collection('users')
    .doc(request.auth.uid)
    .set({ fcmTokens: admin.firestore.FieldValue.arrayRemove(token) }, { merge: true });
  return { ok: true };
});

/** Welcome notification used by the onboarding flow and by tests. */
export const sendWelcome = onCall<{ uid: string }>(async (request) => {
  if (request.auth?.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Admins only.');
  }
  const uid = request.data?.uid;
  if (!uid) throw new HttpsError('invalid-argument', 'Missing uid.');

  const [recipient] = await loadRecipients([uid]);
  if (!recipient) throw new HttpsError('not-found', 'Unknown member.');

  const locale = normalizeLocale(recipient.locale);
  await deliver(recipient, {
    kind: 'welcome',
    title: t('mentionTitle', locale),
    body: t('messageBody', locale, { actor: 'CTG', channel: '#general', text: '' }),
    route: '/chat/c_general',
  });
  return { ok: true };
});
