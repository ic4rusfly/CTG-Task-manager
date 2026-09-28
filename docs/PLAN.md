# CTG Hub — Product & Technical Plan

> **One app for CTG members: team chat (Slack-like) + task management (Jira-like) + a shared agenda.**
> Flutter (Android, iOS, Web, Windows/macOS/Linux) + Firebase. Trilingual: العربية / Français / English.

---

## 1. Product scope

### 1.1 Who uses it
| Role | Capabilities |
|---|---|
| `member` | Chat (channels + DMs), see & update own tasks, see agenda, edit own profile, pick language |
| `lead` | Everything a member can + create tasks, assign to members of **their** team, create channels, create agenda events |
| `admin` | Everything + invite/deactivate members, assign tasks to individuals **or groups**, manage teams, global announcements, delete content |

### 1.2 Core feature set (v1)

**A. Identity and profile**
- Email/password + Google sign-in (Firebase Auth). Invite-only: an admin pre-creates the member record, or signup is restricted to a whitelisted CTG email domain.
- Profile: avatar, full name, role/job title, team, phone, bio, skills/tags, timezone, preferred language, online/last-seen presence.
- Member directory with search + filter by team/skill. Tap a member → profile → "Message" / "Assign task".

**B. Messaging (the Slack part)**
- `#general` channel auto-created and every member auto-joined.
- Public channels, private channels, and 1-to-1 DMs (also group DMs).
- Message types: text (with markdown-lite), **images**, **files/docs**, **audio/music + voice notes**, **links with rich preview**, and task-reference chips (`#TASK-142` renders as a live card).
- Threads (replies on a message), named reactions (no emoji), edit/delete own message, pin messages, @mentions (`@user`, `@channel`) that trigger push notifications.
- Typing indicators, read receipts (per-channel `lastReadAt`), unread badges.
- Search across messages the user can access.

**C. Tasks (the Jira part)**
- Entities: **Project → Task → Subtask/Checklist → Comment**.
- Task fields: key (`CTG-142`), title, description, status, priority, type, assignees (many), reporter, team, labels, due date, estimate (hours), **progress %**, attachments, watchers, activity log.
- Statuses: `backlog → todo → in_progress → review → done` (+ `blocked`). Configurable per project.
- Views: **Kanban board** (drag between columns), **list** with filters/sort, **My tasks**, **Team tasks**, **Calendar view** (by due date).
- Progress: slider 0–100% **or** auto-computed from checklist completion; moving to `done` forces 100%.
- Assignment: admin/lead picks individuals **or a group** (team, or ad-hoc multi-select) → either one shared task with N assignees, or "clone per person" (N separate tasks) — a toggle in the assign dialog.
- Per-task comment thread; each task has an optional linked chat thread.
- Notifications on assign, mention, status change, due-soon (24h) and overdue.

**D. Shared agenda**
- Month / week / agenda-list views.
- Event: title, description, start/end (or all-day), location or meeting URL, color, attendees (individuals or whole team), recurrence (daily/weekly/monthly), reminders.
- Sources merged into one calendar: manual events + task due dates + member birthdays/leave (optional later).
- Invite responses: going / maybe / declined.
- ICS export + optional Google Calendar sync (v2).

**E. Internationalization**
- Full UI in **ar / fr / en**, chosen per user, stored in profile and synced across devices.
- **RTL layout** for Arabic (`Directionality` handled by Flutter automatically via locale).
- Localized dates/times/numbers via `intl`; Arabic uses Gregorian calendar with Arabic numerals option.
- Push notification bodies are composed **server-side in the recipient's language** (Cloud Function reads `user.locale`).
- User-generated content is never translated (optionally an on-demand "translate" button in v2).

### 1.3 Explicitly out of scope for v1
Voice/video calls, sprints & story points & burndown charts, time tracking/timesheets, external guest access, workflow automation rules, SSO/SAML.

---

## 2. Architecture

```
┌────────────────────────── Flutter client ──────────────────────────┐
│  Presentation (screens/widgets)  —  Riverpod providers             │
│  Domain (models + repository interfaces)                           │
│  Data (FirebaseXRepository  |  MockXRepository)                    │
└───────────────┬────────────────────────────────────────────────────┘
                │ Firebase SDKs (realtime streams)
┌───────────────▼────────────────────────────────────────────────────┐
│ Auth │ Cloud Firestore │ Cloud Storage │ FCM │ Cloud Functions      │
└────────────────────────────────────────────────────────────────────┘
```

- **State management:** Riverpod (`flutter_riverpod`) — repositories exposed as providers, screens consume `StreamProvider`s. Swapping `MockXRepository` for `FirebaseXRepository` is a one-line override, which is how the UI runs today with no backend.
- **Routing:** `go_router` with a `StatefulShellRoute` bottom-nav shell and auth redirect guard. Deep links: `/tasks/:id`, `/chat/:channelId`, `/agenda/:eventId` (same URLs on web).
- **Layering rule:** UI never imports `cloud_firestore`. Only `lib/data/**` does.
- **Offline:** Firestore local persistence is enabled (on by default on mobile, opt-in on web) → read cache + queued writes for free, which covers the 50–500 user / "offline nice-to-have" target.
- **Responsive:** `< 700 px` → bottom nav + single pane; `≥ 700 px` → navigation rail + master/detail (channel list | conversation, task list | task detail). Same code for web & desktop.

### 2.1 Folder structure
```
lib/
  main.dart                 app bootstrap, Firebase init, mock switch
  app.dart                  MaterialApp.router, theme, locale
  router.dart               go_router config + guards
  core/
    theme.dart  constants.dart  formatters.dart  responsive.dart  env.dart
  l10n/                     app_en.arb  app_fr.arb  app_ar.arb
  domain/
    models/                 app_user, team, channel, message, project, task,
                            task_comment, event, notification
    repositories/           abstract interfaces (auth, users, chat, tasks, agenda)
  data/
    mock/                   in-memory implementations + seed data
    firebase/               Firestore/Storage implementations
  providers/                riverpod providers wiring domain ↔ data
  features/
    auth/ home/ chat/ tasks/ agenda/ directory/ profile/ admin/
  widgets/                  shared UI (avatar, empty_state, progress_ring, ...)
```

---

## 2.2 Design system (non-negotiable)

**Palette** — greys and deep green, with chocolate and maroon as the only accents. No saturated
"default AI" blues/violets/teals, no gradients, no neon.

| Token | Light | Dark | Used for |
|---|---|---|---|
| green (primary) | `#2E4A3A` | `#3E6B52` | primary actions, selection, in-progress |
| green soft | `#3E6B52` | `#4F8266` | done, presence, positive progress |
| chocolate | `#6B4A32` | `#8A6347` | review status, high priority, secondary accent |
| maroon | `#6E2C2C` | `#8E4141` | blocked, urgent, overdue, destructive |
| grey / grey dark | `#6E7671` / `#3A403C` | `#8C948E` / `#333A35` | text dim, borders, backlog |
| background / surface | `#F2F3F1` / `#FAFAF8` | `#141714` / `#1C201D` | app chrome |

Both themes ship from day one (`ThemeMode.system` by default, switchable in Settings).

**No emoji** anywhere — not in the UI, not in seed data, not in copy. Reactions are named codes
(`ack`, `agree`, `watching`, `blocker`, `done`) rendered as line icons with translated labels, so
they render identically on every OS and stay localisable in ar/fr/en.

Other rules: 1px borders instead of heavy shadows; 8–14px radii; line icons only; `start`/`end`
padding (never left/right) so Arabic mirrors correctly; Inter for Latin, Noto Kufi Arabic for
Arabic.

---

## 3. Data model (Firestore)

```
users/{uid}
  displayName, email, photoUrl, title, teamId, phone, bio, skills[],
  role: member|lead|admin, locale: en|fr|ar, themeMode, fcmTokens[],
  presence: online|away|offline, lastSeenAt, createdAt, active

teams/{teamId}            name, description, memberIds[], leadId, color

channels/{channelId}
  name, topic, type: general|public|private|dm|groupDm,
  memberIds[], createdBy, createdAt, lastMessage{text,senderId,sentAt},
  lastReadAt: { uid: Timestamp }            // unread computation
  ── messages/{messageId}
       senderId, type: text|image|file|audio|link|system|taskRef,
       text, attachments[{url,name,mime,size,width,height,durationMs}],
       taskId?, replyToId?, threadCount, reactions:{ "ack":[uid,...] },
       mentions[uid], sentAt, editedAt, deleted

projects/{projectId}      key: "CTG", name, teamId, statuses[], memberIds[]

tasks/{taskId}
  key: "CTG-142", projectId, title, description,
  status, priority: low|medium|high|urgent, type: task|bug|feature,
  assigneeIds[], reporterId, teamId, labels[], progress: 0..100,
  dueAt, estimateHours, checklist[{id,text,done}], attachments[],
  watcherIds[], groupAssignmentId?, createdAt, updatedAt, completedAt, order
  ── comments/{commentId}  authorId, text, attachments[], createdAt
  ── activity/{entryId}    actorId, kind, from, to, at

events/{eventId}
  title, description, startAt, endAt, allDay, location, meetingUrl,
  color, createdBy, attendeeIds[], teamIds[], rsvp:{uid:going|maybe|no},
  recurrence{freq,interval,until}, reminderMinutes[], relatedTaskId?

notifications/{uid}/items/{id}   kind, title, body, route, read, createdAt
```

**Indexes needed:** `tasks(assigneeIds array-contains, status, dueAt)`, `tasks(projectId, status, order)`, `events(startAt)`, `channels(memberIds array-contains, lastMessage.sentAt desc)`, `messages(sentAt desc)`.

**Security rules (summary)** — full file in `firebase/firestore.rules`:
- Everything requires `request.auth != null` **and** `users/{uid}.active == true`.
- `users`: read all, write only own doc; `role` and `active` writable only by admin (enforced by custom claim `admin: true`).
- `channels`: read/write messages only if `uid in channel.memberIds`; private channel membership changes only by admin/creator.
- `tasks`: read if member of the project/team; create/delete if admin/lead; a normal assignee may update **only** `status`, `progress`, `checklist`, and add comments.
- `events`: read all; write by creator, lead, or admin.
- Storage: `chat/{channelId}/...` and `tasks/{taskId}/...` readable by channel/task members only; 25 MB per upload cap; mime whitelist.

**Cloud Functions (Node/TS):**
`onTaskWrite` → notify assignees + activity log · `onMessageCreate` → fan-out FCM to channel members (respecting mute + locale) · `onUserCreate` → add to `#general`, set custom claims · `dueSoonScheduler` (hourly cron) · `onEventCreate` → invites/reminders · `assignTaskGroup` (callable) → bulk create/assign with one write batch.

---

## 4. Internationalization plan

- `flutter_localizations` + **ARB files** (`lib/l10n/app_{en,fr,ar}.arb`), generated with `flutter gen-l10n` → `AppLocalizations.of(context)`.
- Locale resolution order: user profile `locale` → device locale → `en`.
- Language switcher in Settings; change writes to Firestore and updates a Riverpod `localeProvider` instantly (no restart).
- RTL: never hardcode `left/right` — always `start/end` (`EdgeInsetsDirectional`, `Align(alignment: AlignmentDirectional...)`). Chat bubbles mirror correctly. Icons that imply direction use `Transform.flip` under RTL.
- Arabic font: **Noto Kufi Arabic / Cairo**; Latin: **Inter**. Both bundled so rendering is identical on web & desktop.
- Pluralization & dates via ICU syntax in ARB (`{count, plural, ...}`) and `DateFormat.yMMMMd(locale)`.
- Translation workflow: `app_en.arb` is the source of truth; a CI check fails the build if `fr`/`ar` are missing any key.

---

## 5. Delivery roadmap

| Phase | Duration | Deliverable |
|---|---|---|
| **0. Foundations** *(done — this commit)* | — | Project skeleton, routing, theming, i18n ar/fr/en, models, repository interfaces, mock data, all screens clickable |
| **1. Firebase wiring** *(rules, Functions, seed and CI landed)* | 1 week | Real project, Auth (email + Google), Firestore repos replacing mocks, security rules, seed script |
| **2. Chat** *(mentions, search, threads and media upload landed)* | 1.5 weeks | Channels, DMs, media upload (image/file/audio/voice note), reactions, threads, unread & read receipts, search |
| **3. Tasks** | 1.5 weeks | Projects, kanban DnD, filters, task detail, comments, checklist, progress, attachments, activity log |
| **4. Assignment & admin** | 1 week | Group assignment (shared vs per-person clone), member management, teams, roles/claims |
| **5. Agenda** | 1 week | Month/week/list views, events, recurrence, RSVP, task due dates merged, reminders |
| **6. Notifications** *(in-app centre and FCM registration landed)* | 0.5 week | FCM + Cloud Functions, per-recipient-language payloads, in-app notification center, mute settings |
| **7. Polish & release** | 1 week | Empty/error/loading states, a11y, dark mode, responsive web/desktop, analytics & Crashlytics, tests, CI (GitHub Actions), Play/App Store + Firebase Hosting |

**Total ≈ 8–9 weeks** for one full-time Flutter dev (plus ~1 week of part-time backend/Functions work that can overlap).

### Testing & CI
- `flutter test` unit tests on models/logic, widget tests per screen driven by mock repositories, `integration_test` for the login → assign task → chat happy path.
- GitHub Actions: `analyze` + `test` + `build web` on PR; `flutter build apk/ipa/web` + Firebase Hosting deploy on `main`.

### Cost (Firebase, ~200 active members)
Blaze plan, realistically **$0–25/month**: Firestore reads dominate (chat streams), Storage a few GB, FCM free. Keep costs down by paginating messages (limit 50 + `startAfter`), caching avatars, and avoiding broad `collectionGroup` listeners.

### Main risks
| Risk | Mitigation |
|---|---|
| Firestore read costs from always-on chat listeners | Paginate, detach listeners on screens not visible, cache `lastMessage` on the channel doc |
| Security rules complexity | Rules unit tests with the emulator suite, run in CI |
| Arabic RTL regressions | Golden tests in all 3 locales for key screens |
| Scope creep (calls, sprints, timesheets) | Locked v1 scope above; everything else is v2 backlog |

---

## 6. What is in this repository right now

- `docs/PLAN.md` — this document.
- Flutter app source (`lib/`) — full structure, models, repository interfaces, **mock** repositories with realistic CTG seed data **and the Firestore/Auth implementations**, all v1 screens, and complete ar/fr/en translations. `flutter run` uses the mocks; `--dart-define=BACKEND=firebase` uses the real backend.
- `firebase/` — Firestore rules, indexes and Storage rules; `functions/` (TypeScript Cloud Functions, type-checked in CI); `seed/` (project bootstrap script); `seed/` (project bootstrap script). The Firestore/Auth repositories now live in `lib/data/firebase/` behind `--dart-define=BACKEND=firebase`.
- `test/` — unit and widget tests; `.github/workflows/ci.yml` — analyze, test, web build, translation and no-emoji gates, Functions type-check.
- `prototype/` — a self-contained clickable HTML mock of the same UI (used for the live preview in this environment, where the Flutter SDK cannot be installed). It reads the same ARB translations as the app.
- `tool/` — `gen_l10n.py` (ARB to Dart) and `gen_prototype_i18n.py` (ARB to prototype).
