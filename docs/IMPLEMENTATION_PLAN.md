# CoachSpace — Implementation plan

> The order in which CoachSpace is built, phase by phase, so that it can be tried and stays stable at every
> step. Written for the implementer (Claude Opus). Status of each phase lives in `PROGRESS.md`.
>
> **Rules for every phase**
> 1. Work on the branch given by the session; open a pull request only when the owner asks.
> 2. Build the database-facing part and the example-data part of each repository method together.
> 3. A phase is finished only when its "Done when" list is true, `npm run check` and the database tests pass,
>    the running app was looked at (web preview; devices where the phase says so), `PROGRESS.md` is updated and
>    the owner got a preview with a short summary in Spanish.
> 4. Do not start the next phase without the owner's go-ahead. Small decisions: decide, write them in the
>    relevant document, continue. Product changes: stop and ask.
> 5. Never apply a migration to production, create paid resources or submit to a store without approval.

## Overview

| Phase | Name | Kind | Depends on | Owner must do first |
|---|---|---|---|---|
| 0 | Foundation hardening | Infrastructure | — | Nothing |
| 1 | Backend bring-up and sign-in | Infrastructure | 0 | Create the Supabase account and project; add secrets |
| 2 | Teams, joining, roster | MVP | 1 | — |
| 3 | Events, availability, Home, Calendar | MVP | 2 | — |
| 4 | Notifications and reminders | MVP | 3 | Expo account; an Android phone at hand |
| 5 | Register, announcements, chat, documents | MVP | 3 (4 for announcements' push) | — |
| 6 | Beta readiness for level 1 | Infrastructure | 2–5 | Decide store fees (O-005), domain (O-010), privacy notice (O-011), Dutch review (O-012) |
| 7 | Level 2: statistics, coach notes, lifts, tasks, squad, polls | MVP for the beta (D-016) | 3, 5 | — |
| 8 | Coach Pro: library, plans, assignments | Later feature | 3 | — |
| 9 | Beta with the owner's club | Release | 6 (and what is ready of 7) | Approve the release; production project |
| — | After the beta | Future | 9 | — |

Phases 5 and 7 are lists of independent slices; each slice is delivered and reviewed on its own.
**Checkpoint, mid-January 2027:** with the owner, decide which slices of phase 7 ship in the February beta.
Level 1 (phases 1–6) is never cut.

---

## Phase 0 — Foundation hardening

**Goal:** the existing foundation matches the documentation and is ready to carry real features.

| Task | Area |
|---|---|
| Remove absence reasons: `AbsenceReason`, `reason` in the example data, the `reason.*` texts, their use in the event screen (D-024) | `src/data`, `src/i18n`, `src/app/event` |
| Import each font file from its own path instead of the package index (the index pulls every weight into the web bundle) | `src/theme/fonts.ts` |
| Add Dutch: `src/i18n/nl.ts`; first launch follows the device language (`expo-localization`); remember the choice on the device | `src/i18n`, More |
| Force the light appearance (`userInterfaceStyle`), replace template splash and icon colours with black/white placeholders | `app.json` |
| Add TanStack Query; split `Repository` by area (`ARCHITECTURE.md` §5); replace the hand-made `useQuery` | `src/data`, `src/hooks`, `src/features` |
| Choose the data source from `EXPO_PUBLIC_DATA_SOURCE`; update `.env.example` | `src/data/index.ts` |
| Unit tests: add Jest (`jest-expo`) and React Native Testing Library; test `src/domain/` (totals, countdown, formatting, initials) | `package.json`, `src/domain` |
| End-to-end tests: Playwright on the web build with example data (home → event → back; language change) | `tests/e2e/` |
| `npm run check` runs lint, types, unit tests, database tests (when `psql` is available) and the web build; CI runs all | `package.json`, `.github/workflows/ci.yml` |
| Error boundary at the root with the error state | `src/app/_layout.tsx` |
| Preview hosting: publish the web build with example data to a free static host and give the owner a permanent link (D-028) | Hosting config |
| Remove the "Demo data" note in More (D-030) | `src/app/(tabs)/more.tsx` |

- **Database changes:** none.
- **Tests:** the new unit and end-to-end tests pass in CI.
- **Done when:** no trace of absence reasons remains; three languages switch live; CI runs lint, types, unit tests, database tests, end-to-end tests and the web build, all green;
  the owner has a permanent preview link; the web bundle no longer contains unused font weights.
- **Risks:** TanStack Query and Jest versions must match Expo SDK 58 and React 19 — check the Expo docs for
  the SDK before installing; the Expo installer cannot reach its service from the cloud, so take versions
  from `expo/bundledNativeModules.json` or the docs.

## Phase 1 — Backend bring-up and sign-in

**Goal:** a real person signs in on the development project and sees an empty app.

| Task | Area |
|---|---|
| Follow `SETUP_SUPABASE.md` with the owner: project `coachspace-dev` in an EU region, secrets in the Claude environment | External |
| Apply the four migrations and `after_migrations.sql`; run the access tests against the hosted project's roles where possible | `supabase/` |
| Generate database types | `src/data/supabase/database.types.ts` |
| Supabase client with session storage (secure storage on phones, local storage on web) | `src/lib/supabase.ts` |
| `AuthRepository` (both implementations); screens Welcome/Email, Code, Your name; session gate in the root layout; sign out | `src/app/(auth)`, `src/features/auth` |
| Profile creation at first sign-in; language saved in the profile | `src/features/auth` |
| Start screen (no team) with its two choices leading nowhere yet but "Create a team" (phase 2) — build both in one delivery if small | `src/app/start.tsx` |
| Integration script: sign in two test accounts with the service key and check that one cannot read the other's profile | `supabase/tests/integration/` |

- **Database changes:** migrations applied to development (first time). From this moment migrations are
  never edited, only added.
- **Tests:** unit tests for the auth hooks on example data; integration script; manual sign-in on web and on
  an Android development build.
- **Done when:** F-01 acceptance criteria hold on the web preview pointed at development; the session
  survives a restart; wrong and expired codes show the right messages.
- **Risks:** email delivery on the free plan is rate-limited — check the current limit and, if it blocks
  testing, configure a free transactional email service (needs the owner's approval if it could cost);
  the code must be in the email template; session storage APIs differ per platform.

## Phase 2 — Teams, joining, roster

**Goal:** a coach creates a team, loads the roster and lets people in by link. Covers F-02, F-03, F-04.

| Slice | Contents |
|---|---|
| 2a Teams | Create team, team switcher, team settings (name, sport, season start, reminder hours, chat mode) |
| 2b Roster | Team → Players, add/edit/remove player, positions per sport (`src/domain/sports.ts`), roles |
| 2c Joining | Share link, `/join/[token]`, "Who are you?", Waiting, Join requests with approve (new or existing player) and reject, coach invitation |

- **Database changes:** none expected. If a rule is missing, add a migration and a test.
- **Tests:** unit tests for name matching in "existing player" suggestions; component tests for permission
  differences (coach vs player); end-to-end on example data: create team → add player → approve request.
- **Done when:** acceptance criteria of F-02 to F-04; two real accounts (coach on web, parent on a phone)
  complete the join flow against development.
- **Risks:** deep links from an invitation into the app are not possible before a domain exists — the web
  page plus "paste the link" covers it until phase 6.

## Phase 3 — Events, availability, Home, Calendar

**Goal:** the core loop works end to end. Covers F-05, F-06, F-13, F-14.

| Slice | Contents |
|---|---|
| 3a Events | New event and Edit (all types, repeat), cancel and restore, "this / this and following" |
| 3b Event screen | Hero, who's coming, coach records an answer |
| 3c Answering | Slide to answer (Reanimated + Gesture Handler, accessible alternative), "I can't come", change answer, optimistic update, haptics, live totals |
| 3d Home | Role-aware Home with next event, coming up, empty states (Needs you rows arrive with their features) |
| 3e Calendar | List and Month |

- **Database changes:** none expected.
- **Tests:** unit tests for next-event selection, month grid, countdown; component tests for the answer
  control states; end-to-end: coach creates a weekly training, player answers, coach sees the total change.
- **Done when:** acceptance criteria of F-05, F-06, F-13, F-14; the slide works with touch, mouse and
  keyboard, and with a screen reader through its button.
- **Risks:** gesture feel on web vs native; time zones around clock changes (tested in the database, check
  the display); optimistic updates rolling back cleanly.

## Phase 4 — Notifications and reminders

**Goal:** people are told. Covers F-07, F-12.

| Task | Area |
|---|---|
| Development build for Android (and iOS when an iPhone is available); push permission flow; store tokens | `src/lib/notifications.ts` |
| Edge Function `send-push` + database webhook on `notifications`; texts per language | `supabase/functions/send-push` |
| Notification list screen and Home's bell; opening the right screen from a push | `src/app/notifications.tsx` |
| "Remind N players" on Home and Event; "Reminder sent" state; "No account yet" marks | `src/features/events` |
| Scheduler for automatic reminders (already in `after_migrations.sql`); verify it fires | Supabase |

- **Database changes:** none expected; the webhook is configuration.
- **Tests:** unit tests for notification texts in three languages; integration: inserting a notification row
  produces a push on a real device; manual check of each row of `DATABASE.md` §5.
- **Done when:** acceptance criteria of F-07 and F-12 on a real Android phone (and iPhone when available).
- **Risks:** iOS push needs an Apple developer account (O-005) — without it, iOS is verified later;
  push credentials set-up in EAS; webhook retries causing duplicates (use `pushed_at`).

## Phase 5 — Register, announcements, chat, documents

**Goal:** level 1 is complete. Covers F-08 to F-11.

| Slice | Contents |
|---|---|
| 5a Register | Register screen, pre-fill rule, "Register to take" on Home |
| 5b Announcements | List, new, delete, pinned on Home, unread mark |
| 5c Chat | Messages with live updates, pagination, delete, coaches-only mode, unread dot |
| 5d Documents | List, upload with progress, links, open, rename, delete |

- **Database changes:** none expected.
- **Tests:** unit test for the pre-fill rule; component tests for chat states; integration: file upload and a
  second team's account refused; end-to-end on example data for each slice.
- **Done when:** acceptance criteria of F-08 to F-11.
- **Risks:** file picking and opening differ per platform; live updates need the publication set in
  `after_migrations.sql`; keyboard handling in chat on small phones.

## Phase 6 — Beta readiness (level 1)

**Goal:** level 1 can be put in the hands of the club.

| Task | Notes |
|---|---|
| Account deletion (Edge Function `delete-account`) and "Leave this team" | Required by the stores and by GDPR |
| Accessibility pass on every screen (`FEATURE_SPECIFICATIONS.md`, cross-cutting) | Screen reader on Android and iOS |
| All texts in three languages; Dutch reviewed by a native speaker (O-012) | |
| App icon, splash, store texts and screenshots in the Matchday identity | Icon design approved by the owner first |
| EAS Build profiles (development, preview, production); internal distribution for Android; TestFlight when the Apple account exists | O-005 |
| Domain and universal links for `/join/<token>` | O-010 |
| Production Supabase project: migrations, `after_migrations.sql`, email template, backups setting | Owner's approval |
| Privacy notice and terms linked from Welcome and Your account | O-011; text provided by the owner after professional review |
| Error reporting: decide with the owner whether to add a crash reporter (privacy and cost) | |
| Full regression on devices: the main flows per role | |

- **Done when:** a tester installs the app from a link, joins by invitation and completes the core loop; the
  account can be deleted; nothing in `FEATURE_SPECIFICATIONS.md` level 1 is failing.
- **Risks:** store review times; Apple requires account deletion and a privacy policy; free-tier limits of
  the production project must be read before real use.

## Phase 7 — Level 2

Independent slices, in this order (cheapest and most asked first). Covers F-16 to F-21.

| Slice | Contents | Depends on |
|---|---|---|
| 7a Statistics | Team → Stats for coaches and for players | 5a |
| 7b Coach notes | Notes section, "From last time" | 3b |
| 7c Lifts | Lifts section | 3b |
| 7d Tasks | Tasks section | 3b |
| 7e Squad | Squad screen, publish, player view | 3b, 4 |
| 7f Polls | Team → Polls, Needs you row | 4 |

- **Database changes:** none expected (migration 2 is already applied).
- **Tests:** unit tests for statistics; component tests per slice; database tests already cover the rules.
- **Done when:** the acceptance criteria of each slice's feature.
- **Risks:** time before February (D-016). The mid-January checkpoint decides what ships.

## Phase 8 — Coach Pro

Covers F-22 to F-24: Library screens, plan editor, plan in the event, assignments, the "not enabled" state.
Entitlements granted by hand in the database (`SETUP_SUPABASE.md`). No purchase flow.

- **Done when:** acceptance criteria of F-22 to F-24; a coach without the entitlement cannot create anything
  (database test) and sees the explanation.
- **Risks:** scope creep — the demo's library had more (templates, sport filters, cover images); none of it
  is in scope.

## Phase 9 — Beta

Release level 1 (+ ready slices of level 2) to the owner's club; collect feedback in `RESEARCH.md`; fix.
Needs the owner's explicit approval, the production project and the items of phase 6.

## After the beta (not planned in detail)

Purchases for Coach Pro and prices (O-004) · desktop layout for coaches · level 3 (kitty and fines, treasurer,
club panel) · calendar subscription · push for chat mentions · offline editing · accounts for under-16s with
guardian authorisation · images in chat.

---

## How to run and verify (for the implementer)

| What | How |
|---|---|
| Install | `npm ci` |
| All static checks and web build | `npm run check` |
| Database tests | `supabase/tests/run.sh` (needs PostgreSQL 16; in the cloud session start a local server or use the CI job) |
| Web app with example data | `EXPO_PUBLIC_DATA_SOURCE=demo npm run build:web`, serve `dist/`, look at it with Playwright at 390 × 844 and take screenshots |
| Web app against development | the same with `EXPO_PUBLIC_DATA_SOURCE=supabase` and the two public Supabase variables |
| Preview for the owner | Publish the web build to the preview host and send the link. The owner never runs commands (D-013) |
| Devices | EAS development or preview build; the owner installs from a link or QR |
| New migration | Add a file in `supabase/migrations/`, add checks to `access_test.sql`, run the tests, apply to development, regenerate types |
