# Changelog

All notable changes to CTG Hub. Dates are ISO, newest first.

## 0.1b - 2026-09-29

First feature-complete beta of the v1 scope: chat, tasks and the shared
agenda, in Arabic, French and English, on mobile, web and desktop. The app
runs on in-memory mock data by default and on Firebase with
`--dart-define=BACKEND=firebase`.

### Chat
- Channels, private channels and direct messages, with unread counts.
- Attachments picked from the device and uploaded to Cloud Storage
  (`chat/{channelId}/...`), with a progress bar, a 25 MB limit matching the
  Storage rules, and inline retry on failure.
- Threads: reply to any message, "N replies" chip, replies kept out of the
  channel timeline, reply notifications to the root author only.
- Mentions with `@`, highlighted in the bubble and resolved unicode-aware, so
  Arabic and French names match.
- Full-text search across every conversation the member belongs to.
- Message editing with an "edited" marker, and soft delete.
- Reactions as named codes (`ack`, `agree`, `watching`, `blocker`, `done`) -
  never emoji.
- Per-conversation mute (mentions still get through) and read receipts:
  Sent, Seen, Seen by N members.

### Tasks
- Board and list views, drag and drop, filters, task detail with checklist,
  progress, comments and due dates.
- Assignment to an individual, or to a group as one shared task or one task
  per person (transactional `CTG-###` keys through the `assignTaskGroup`
  callable).
- Attachments uploaded to `tasks/{taskId}/...` through the same media layer
  as chat.
- Activity trail: created, assigned, status, progress and attachments, in the
  reader's language.

### Agenda
- Month and list views, events with attendees, RSVP, and task due dates
  merged into the calendar.

### Notifications
- In-app notification centre with unread badge and mark-all-read.
- FCM device registration through the `registerDevice` / `unregisterDevice`
  callables, an in-app banner for foreground messages, and routing from a
  tapped notification - including cold start and web background push.
- Every notification is composed in the **recipient's** language, by the
  Cloud Functions in production and by the mock notifier in the demo build.

### Platform
- Flutter + Riverpod + go_router, mock-first architecture: the UI never
  imports Firebase, backends are swapped as provider overrides.
- Firestore rules and indexes, Storage rules, seed script and nine Cloud
  Functions (`europe-west1`).
- Localisation without code generation: `tool/gen_l10n.py` turns the ARB
  files into Dart, and `tool/gen_prototype_i18n.py` feeds the prototype the
  same strings. 190 keys in each of the three languages.
- Design system: grey and deep green with chocolate and maroon accents,
  light and dark themes, RTL-safe layout, no emoji anywhere.
- Clickable HTML prototype mirroring the app screen for screen, covered by a
  headless jsdom smoke test (55 checks) that runs in CI next to
  `flutter analyze`, `flutter test`, the web build and the Functions
  type-check.

### Known limitations
- Search is client-side over streamed conversations; a Firestore or Algolia
  index is the next step.
- Voice notes are uploaded as files; there is no in-app recorder or player
  scrubbing yet.
- `web/firebase-messaging-sw.js` needs the project identifiers from
  `flutterfire configure` before web background push works.
