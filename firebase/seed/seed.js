#!/usr/bin/env node
/**
 * Seeds a fresh CTG Hub Firebase project: teams, the #general channel and the
 * founding members (Auth user + users/{uid} profile + custom claims).
 *
 * Usage:
 *   npm install
 *   export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
 *   node seed.js                 # create / update
 *   node seed.js --emulator      # against the local emulator suite
 *
 * Safe to re-run: every write is a merge, no data is deleted.
 */
const admin = require('firebase-admin');

const EMULATOR = process.argv.includes('--emulator');
if (EMULATOR) {
  process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
}

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'ctg-hub' });
const db = admin.firestore();
const auth = admin.auth();

const DEFAULT_PASSWORD = process.env.CTG_SEED_PASSWORD || 'ChangeMe!2026';

const TEAMS = [
  { id: 't1', name: 'Core', colorValue: 0x2e4a3a, leadId: 'yasmine' },
  { id: 't2', name: 'Tech', colorValue: 0x3e6b52, leadId: 'omar' },
  { id: 't3', name: 'Events and Comms', colorValue: 0x6b4a32, leadId: 'mehdi' },
];

const MEMBERS = [
  { handle: 'yasmine', displayName: 'Yasmine Bennani', email: 'yasmine@ctg.ma', title: 'Program Director', teamId: 't1', role: 'admin', locale: 'fr' },
  { handle: 'omar', displayName: 'Omar El Idrissi', email: 'omar@ctg.ma', title: 'Tech Lead', teamId: 't2', role: 'lead', locale: 'en' },
  { handle: 'salma', displayName: 'Salma Ait Taleb', email: 'salma@ctg.ma', title: 'Designer', teamId: 't2', role: 'member', locale: 'ar' },
  { handle: 'mehdi', displayName: 'Mehdi Ouazzani', email: 'mehdi@ctg.ma', title: 'Events Coordinator', teamId: 't3', role: 'lead', locale: 'fr' },
  { handle: 'nour', displayName: 'Nour Haddad', email: 'nour@ctg.ma', title: 'Communications', teamId: 't3', role: 'member', locale: 'ar' },
];

async function ensureUser(member) {
  let record;
  try {
    record = await auth.getUserByEmail(member.email);
  } catch (_) {
    record = await auth.createUser({
      email: member.email,
      password: DEFAULT_PASSWORD,
      displayName: member.displayName,
    });
    console.log('created auth user', member.email);
  }
  await auth.setCustomUserClaims(record.uid, {
    admin: member.role === 'admin',
    lead: member.role === 'lead',
  });
  await db.collection('users').doc(record.uid).set(
    {
      displayName: member.displayName,
      email: member.email,
      title: member.title,
      teamId: member.teamId,
      role: member.role,
      locale: member.locale,
      skills: [],
      bio: '',
      phone: '',
      active: true,
      online: false,
      fcmTokens: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return record.uid;
}

async function main() {
  const uids = {};
  for (const member of MEMBERS) {
    uids[member.handle] = await ensureUser(member);
  }

  for (const team of TEAMS) {
    const memberIds = MEMBERS.filter((m) => m.teamId === team.id).map((m) => uids[m.handle]);
    await db.collection('teams').doc(team.id).set(
      {
        name: team.name,
        description: '',
        colorValue: team.colorValue,
        leadId: uids[team.leadId] ?? null,
        memberIds,
      },
      { merge: true }
    );
  }

  const everyone = Object.values(uids);
  await db.collection('channels').doc('c_general').set(
    {
      name: 'general',
      type: 'general',
      topic: 'Everything CTG - announcements and daily chatter',
      memberIds: everyone,
      createdBy: uids.yasmine,
      lastMessage: { text: '', senderId: null, sentAt: new Date().toISOString() },
    },
    { merge: true }
  );

  await db.collection('projects').doc('ctg').set(
    {
      key: 'CTG',
      name: 'CTG',
      statuses: ['backlog', 'todo', 'inProgress', 'review', 'done', 'blocked'],
      memberIds: everyone,
    },
    { merge: true }
  );

  await db.collection('counters').doc('tasks').set({ value: 100 }, { merge: true });

  console.log(`seeded ${MEMBERS.length} members, ${TEAMS.length} teams, #general and the CTG project`);
  if (!EMULATOR) console.log(`default password: ${DEFAULT_PASSWORD} - ask everyone to reset it`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
