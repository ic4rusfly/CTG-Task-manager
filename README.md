# CTG Hub

One app for CTG members: **team chat** (Slack-like), **task management** (Jira-like) and a
**shared agenda** — in Arabic, French and English, on Android, iOS, web and desktop.

Built with **Flutter + Riverpod + go_router**, backed by **Firebase** (phase 1).

> Full product and technical plan: [`docs/PLAN.md`](docs/PLAN.md)

---

## What is in the repo

| Path | What it is |
|---|---|
| `lib/` | The Flutter app: models, repository interfaces, mock data layer, all v1 screens, ar/fr/en translations |
| `docs/PLAN.md` | Scope, architecture, Firestore data model, security rules, i18n plan, 9-week roadmap, costs, risks |
| `firebase/` | Firestore rules + indexes, Storage rules, `firebase.json` |
| `firebase/client_reference/` | Firestore + Auth repository implementations to drop in during phase 1 (not compiled yet) |
| `firebase/functions/` | Cloud Functions (TypeScript): notifications in each recipient's language, group assignment, onboarding, due-soon cron |
| `firebase/seed/` | One-shot script that seeds a fresh project with members, teams, `#general` and the CTG project |
| `test/` | Unit tests (models, mock repositories, localisation) and widget tests (task card, RTL, French) |
| `.github/workflows/ci.yml` | CI: translation + no-emoji checks, `flutter analyze`, `flutter test`, web build, Functions type-check |
| `prototype/` | A dependency-free clickable HTML prototype of the same UI (see below) |
| `tool/` | `gen_l10n.py` (ARB → Dart strings) and `gen_prototype_i18n.py` (ARB → prototype) |

The app currently runs entirely on **in-memory mock repositories** with realistic CTG seed data,
so you can click through every screen before any Firebase project exists. Swapping in Firebase is
a provider override — no UI code changes (see `firebase/client_reference/README.md`).

---

## Run the Flutter app

```bash
flutter pub get
flutter run              # phone / emulator
flutter run -d chrome    # web
flutter run -d windows   # or macos
```

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
reviews. You can: chat and attach media, drag task cards across the board, open a task and move
its progress, assign a task to a group (shared or one-per-person), browse the agenda and RSVP,
manage members as admin, and switch language (including RTL Arabic) and theme.

---

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
`registerDevice`.

## Tests

```bash
flutter test                     # unit + widget
cd firebase/functions && npm run typecheck
```

## Roadmap at a glance

Phase 0 foundations (done) → 1 Firebase wiring → 2 chat → 3 tasks → 4 assignment and admin →
5 agenda → 6 notifications → 7 polish and release. Details and estimates in `docs/PLAN.md`.
