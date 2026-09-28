# CTG Hub

One app for CTG members: **team chat** (Slack-like), **task management** (Jira-like) and a
**shared agenda** — in Arabic, French and English, on Android, iOS, web and desktop.

Built with **Flutter + Riverpod + go_router**, backed by **Firebase** (phase 1).

> Full product and technical plan: [`docs/PLAN.md`](docs/PLAN.md)

---

## What is in the repo

| Path | What it is |
|---|---|
| `lib/` | The Flutter app: models, repository interfaces, **mock and Firebase data layers**, all v1 screens, ar/fr/en translations |
| `docs/PLAN.md` | Scope, architecture, Firestore data model, security rules, i18n plan, 9-week roadmap, costs, risks |
| `firebase/` | Firestore rules + indexes, Storage rules, `firebase.json` |
| `firebase/functions/` | Cloud Functions (TypeScript): notifications in each recipient's language, group assignment, onboarding, due-soon cron |
| `firebase/seed/` | One-shot script that seeds a fresh project with members, teams, `#general` and the CTG project |
| `test/` | Unit tests (models, mock repositories, mentions, localisation) and widget tests (task card, RTL, French) |
| `.github/workflows/ci.yml` | CI: translation + no-emoji checks, `flutter analyze`, `flutter test`, web build, Functions type-check |
| `web/` | Web shell plus `firebase-messaging-sw.js` for background web push |
| `prototype/` | A dependency-free clickable HTML prototype of the same UI (see below) |
| `tool/` | `gen_l10n.py` (ARB → Dart strings), `gen_prototype_i18n.py` (ARB → prototype) and `prototype_smoke.js` (headless prototype test) |

By default the app runs entirely on **in-memory mock repositories** with realistic CTG seed data,
so you can click through every screen before any Firebase project exists. The Firestore/Auth
implementations live in `lib/data/firebase/` and are switched on with
`--dart-define=BACKEND=firebase`.

---

## Run the Flutter app

```bash
flutter pub get
flutter run              # phone / emulator - mock data, no backend needed
flutter run -d chrome    # web
flutter run -d windows   # or macos
```

Against a real backend (after `flutterfire configure`):

```bash
flutter run --dart-define=BACKEND=firebase
# web push additionally needs the project's VAPID public key:
flutter run -d chrome --dart-define=BACKEND=firebase --dart-define=VAPID_KEY=BFx...
# or against the local emulator suite:
flutter run --dart-define=BACKEND=firebase --dart-define=USE_EMULATOR=true
#   Android emulator: add --dart-define=EMULATOR_HOST=10.0.2.2
```

`lib/core/env.dart` holds the switch; `lib/data/firebase/firebase_bootstrap.dart` starts Firebase,
turns on the offline cache and returns the six provider overrides that replace the mock
repositories. No screen, model or provider changes between the two modes.

Requires Flutter 3.24 or newer. Sign in with any seeded member (for example `yasmine@ctg.ma`,
role admin) — in demo mode the password is ignored and the member chips on the login screen sign
you straight in.

> Note: FlutterFire does not support Linux desktop; use Android/iOS/web/Windows/macOS there.

## Run the clickable prototype

No toolchain needed — it is plain HTML, CSS and JavaScript:

```bash
python3 -m http.server 3000 --directory prototype
# open http://localhost:3000
```

It mirrors the Flutter UI screen for screen and reads the **same translation files**
(`prototype/i18n.js` is generated from `lib/l10n/*.arb`), so it is safe to use for stakeholder
reviews. You can: chat and attach real files from your machine, reply in a thread, mention a
teammate with `@`, search every message you can see, read the notification centre, drag task
cards across the board, open a task and move
its progress, assign a task to a group (shared or one-per-person), browse the agenda and RSVP,
manage members as admin, and switch language (including RTL Arabic) and theme.

---

## Attachments and threads

- The plus button in the composer opens the real platform file picker
  (`file_picker`, so it works on Android, iOS, web, Windows and macOS). The
  bytes go through `MediaRepository`: **Cloud Storage** under
  `chat/{channelId}/...` in Firebase mode, an in-memory store in the demo
  build, both capped at 25 MB to match `firebase/storage.rules`.
- Uploads show a progress bar in the composer and, if something fails, an
  inline error with a retry action. Pictures are rendered from memory in the
  demo build and from the download URL in production.
- Any message can be turned into a **thread**: long-press (or the thread icon)
  gives "Reply in thread", the root message keeps a "N replies" chip, replies
  are hidden from the channel timeline, and the thread has its own composer.
  A reply notifies the root author — never the whole channel.

## Mute and read receipts

- The bell in the conversation header (or a long press in the list) mutes a
  conversation for **you only**: it stays visible, its unread count goes
  quiet, and it stops notifying. Mentions always get through, on both the
  Cloud Functions path and the mock one.
- Mutes live in `users/{uid}.mutedChannels`, which is the list the Functions
  already honoured; the client writes it with an array union or remove.
- The last message you sent shows a receipt derived from
  `channels/{id}.lastReadAt`: **Sent**, **Seen**, or **Seen by N members**.
  `lib/core/receipts.dart` holds that logic, so it is unit-tested without a
  widget.

## Push notifications

- After sign-in the app asks for permission and registers the device through
  the `registerDevice` callable; signing out calls `unregisterDevice`, so a
  shared phone stops receiving someone else's alerts. The client never writes
  to `users/{uid}.fcmTokens` itself.
- Settings has a **Push notifications** switch showing the real permission
  state (granted, blocked in system settings, or unsupported on this
  platform).
- A notification that arrives while the app is open becomes an in-app banner
  with an **Open** action; tapping a system notification (cold start or
  background) routes straight to the message, thread or task.
- Web background push needs `web/firebase-messaging-sw.js`: replace the four
  placeholder identifiers with the values `flutterfire configure` prints, and
  pass `--dart-define=VAPID_KEY=...`.
- The mock build behaves the same way: `MockPushService` grants permission,
  issues a fake token and replays new notifications as foreground messages, so
  the banner can be demoed with no backend.

## Mentions, search and notifications

- Typing `@Firstname` (or `@email-handle`) in the composer mentions a member: the token is
  highlighted in the bubble and the person gets a notification. `lib/core/mentions.dart` does the
  resolution and is unicode-aware, so Arabic and French names match too.
- The search icon on the conversation list opens a full-text search across every channel and DM
  the signed-in member belongs to (client-side over the streamed messages; a Firestore or Algolia
  index is the phase-2 upgrade).
- The bell tab is the notification centre. Every notification is composed **in the recipient's
  language** — by the Cloud Functions in production, by `MockNotifier` in mock mode — and stores
  a route so tapping it jumps straight to the message or task.

## Design rules

- **Palette:** greys and deep green (`#2E4A3A` / `#3E6B52`), with chocolate (`#6B4A32`) and
  maroon (`#6E2C2C`) as the only accents. Light and dark themes share the same hues.
- **No emoji anywhere** in the UI, data or copy — reactions, statuses and priorities use icons
  and translatable labels (`ack`, `agree`, `watching`, `blocker`, `done`).
- **No hardcoded left/right**: everything uses `start`/`end` so Arabic RTL mirrors correctly.
- Every user-facing string lives in `lib/l10n/app_en.arb` and must exist in `app_fr.arb` and
  `app_ar.arb`; `python3 tool/gen_l10n.py` fails if a key is missing.

## Adding or changing a string

```bash
# 1. edit lib/l10n/app_en.arb (+ the fr and ar files)
python3 tool/gen_l10n.py            # regenerates lib/l10n/app_localizations.dart
python3 tool/gen_prototype_i18n.py  # keeps the prototype in sync
```

## Backend (phase 1)

```bash
cd firebase/functions && npm install && npm run typecheck   # Cloud Functions
cd ../seed && npm install && node seed.js --emulator        # seed the emulator
firebase emulators:start                                    # auth + firestore + functions + storage
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Functions shipped: `onUserCreate` (claims + auto-join `#general`), `onUserRoleChange`
(keeps custom claims in sync), `onMessageCreate` (FCM fan-out, muted channels respected,
copy built in each recipient's `locale`), `onTaskWrite` (assignment + status notifications and
an activity trail), `dueSoonScheduler` (hourly, 24h horizon), `onEventCreate` (invites),
`assignTaskGroup` (transactional group assignment with sequential `CTG-###` keys),
`registerDevice`, `unregisterDevice`.

In-app notifications are written to `notifications/{uid}/items` by the same Functions and read by
`FirestoreNotificationRepository`; the mock backend mirrors the exact same shape.

## Tests

```bash
flutter test                     # unit + widget
cd firebase/functions && npm run typecheck
cd tool && npm install && node prototype_smoke.js   # headless prototype smoke test
```

The prototype smoke test drives the prototype in jsdom: sign-in, navigation,
notifications, search, mentions, threads, a real file upload, all three
languages and the no-emoji rule. It runs in CI next to the Flutter job.

## Roadmap at a glance

Phase 0 foundations (done) → 1 Firebase wiring → 2 chat → 3 tasks → 4 assignment and admin →
5 agenda → 6 notifications → 7 polish and release. Details and estimates in `docs/PLAN.md`.
