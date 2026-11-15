# CoachSpace — Handoff for the implementer (Claude Opus)

> Start here. This document tells you what CoachSpace is, what is decided, how the project is organised,
> what exists, and exactly where to begin. It was written by the architect (Claude Fable) on 15 November 2026
> after the product definition was closed with the owner.

## 1. What you are building

CoachSpace is a team app for coaches and amateur sports clubs — iOS, Android and web from one Expo code base,
with Supabase behind it. A coach schedules trainings and matches; players, or the parents of players under
16, answer "are you coming?" with one gesture; the coach sees who is in, reminds the rest, takes the register
in seconds, and keeps announcements, documents and a team chat in one place. Level 2 adds squad, statistics,
polls, lifts and tasks. A paid module (Coach Pro) adds an exercise library and training plans.

The reference product is TeamPlus. The bet is not more features: it is **less friction to get in and answer**,
a clear identity, and no ads. The first real users will be the owner's own club, in February 2027.

## 2. Who you work with

- **The owner is the founder, not a developer.** He decides product, design and business. Talk to him in
  **Spanish**, plainly. He **never runs Terminal commands**: you run everything and give him a browser preview
  (or a phone build he installs from a link). Code, comments, commits and documents are in English.
- **Your role:** implement, test and fix, phase by phase. You do not need his approval for technical choices
  inside what is documented. You do need it for: anything that changes the product or its scope, anything that
  costs money, production, store submissions, and destructive database operations.
- **The architect's role (Fable):** product and architecture questions, and changes to these documents. If
  you find a contradiction or a gap that is a product decision, stop that piece, say so to the owner, and
  continue with what is not affected.
- Be critical. If something in these documents is wrong or will not work, say it with evidence; do not
  silently build around it and do not silently follow it.

## 3. Read in this order

| # | Document | What you get from it |
|---|---|---|
| 1 | `CLAUDE.md` and `AGENTS.md` | Working rules; Expo rules (check the versioned Expo docs before using any API) |
| 2 | `docs/PRODUCT.md` | Scope, roles, principles |
| 3 | `docs/DECISIONS.md` | Every decision and why; what is still open |
| 4 | `docs/PROGRESS.md` | What exists today and what is next |
| 5 | `docs/IMPLEMENTATION_PLAN.md` | The phases, in order, with "done when" |
| 6 | `docs/ARCHITECTURE.md` | How the code is organised and the rules for it |
| 7 | `docs/DATABASE.md` + `supabase/migrations/` | The data model and permissions |
| 8 | `docs/UX_SPECIFICATION.md` + `docs/DESIGN.md` | Navigation, screens, visual rules |
| 9 | `docs/FEATURE_SPECIFICATIONS.md` | The feature you are about to build |
| 10 | `docs/SETUP_SUPABASE.md` | External services, when a phase needs them |

`RESEARCH.md` is background. The old demo (`Johntrue28/CoachSpacedemo`) is read-only: never modify it, never
copy its code. Its ideas that survive are already in these documents.

## 4. Decisions you must not reopen

| Topic | Decision |
|---|---|
| Stack | Expo SDK 58, React Native, Expo Router, TypeScript; Supabase (EU); no custom server |
| Sign-in | Six-digit email code. No passwords, SMS or social sign-in |
| Minors | Under 16: no account; guardians act. No birth dates, photos, private chats, rankings, absence reasons |
| Joining | By link; a coach approves each request |
| Answers | In / out only; until the event starts; then the register is the record |
| Chat | One team chat, text only; announcements separate; no push for chat messages |
| Navigation | Five tabs for everyone: Home, Calendar, Team, Chat, More |
| Identity | "Matchday": black, white, one orange; Barlow Condensed + Inter Tight; square corners; no shadows |
| Languages | English (source), Spanish, Dutch — no hard-coded text |
| Access | Enforced in the database with row-level security; every table has tests |
| Paid | Library, plans and assignments are Coach Pro, granted by hand; no billing code before the beta ends |
| Example data | Invented clubs and people; no "fictional" labels needed; never real personal data |

## 5. What exists

See the audit in `PROGRESS.md`. In short: the design system in code and six coach screens run on in-memory
example data; the whole database is written and tested locally but applied nowhere; there is no sign-in, no
backend, no player view, no unit tests. Everything under `src/` is a valid starting point — extend it, do not
restart it.

Known leftovers to remove in phase 0: absence reasons (`AbsenceReason`, `reason.*` texts), the "Demo data"
note in More, font imports through the package index, template colours in `app.json`.

## 6. Where to start

1. Read the documents above. Run `npm ci` and `npm run check`; start a local PostgreSQL and run
   `supabase/tests/run.sh`. Both must pass before you change anything.
2. Do **phase 0** of `IMPLEMENTATION_PLAN.md`. It needs nothing from the owner.
3. Meanwhile the owner creates the Supabase project (`SETUP_SUPABASE.md` §1). When he says it is ready, do
   **phase 1**. Ask for secrets only through the secure credential form, never in the chat.
4. Continue phase by phase. After each phase or slice: update `PROGRESS.md`, publish a preview, and tell the
   owner in Spanish what changed, what you verified and how, what is not verified, and what he needs to
   decide or click. Then wait for his go-ahead.

## 7. How to work inside a phase

- **One slice at a time, vertically:** database rule (if any) → repository method in both implementations →
  hook → screen → tests → look at it running.
- **Definition of done for any slice:** acceptance criteria in `FEATURE_SPECIFICATIONS.md` are true; the four
  states (loading, error, empty, filled) exist; three languages; accessible names and focus; works at 320 px
  and in the 600 px column; `npm run check` and database tests pass; you looked at the running app and took
  screenshots; no control is visible that does not work.
- **When the database needs to change:** new migration file, new checks in `access_test.sql`, run the tests,
  apply to development, regenerate types, update `DATABASE.md`. Never edit an applied migration. Destructive
  changes need the owner's approval.
- **When a screen is not in Penpot:** compose it from existing components following `UX_SPECIFICATION.md`.
  If it needs a new visual pattern, build the component, show it to the owner in the preview, and only then
  use it across screens (A-012).
- **When a case is not specified:** choose the simplest behaviour consistent with `PRODUCT.md` §4, write it
  into the specification, continue. Do not add features, settings or controls that are not specified.
- **Verification is evidence, not belief:** never report a check, build or device test as passed unless you
  ran it and saw the result. Say plainly what you could not verify (for example, anything on an iPhone).

## 8. Things that will bite

- **Expo APIs change every SDK.** Read the docs for the version in `package.json` before touching
  notifications, secure storage, linking, fonts, haptics, document picking or the router. `AGENTS.md` explains how.
- **The Expo installer cannot reach its compatibility service from the cloud environment.** Take versions
  from `node_modules/expo/bundledNativeModules.json` and install with npm.
- **The React Compiler is on.** A value read from a module-level object (such as the i18n instance) is not
  reactive: read it through a hook. This already caused one bug (the language tick not moving).
- **`Pressable`'s `focused` state does not exist in React Native's types;** use `Touchable`.
- **Tabs come from `expo-router/js-tabs`** in this SDK, and the custom tab bar receives `emitter` and
  `navigateToTab`, not `navigation`.
- **Hidden tab screens stay mounted on web:** in end-to-end tests, pick the visible element (`.last()` or a
  visibility filter).
- **Supabase-only features are untested** until the project exists: sign-in, file transfer, live updates, the
  scheduler, webhooks. Budget time for them in phases 1, 4 and 5.
- **Free tiers:** read the current limits when setting each service up; nothing in these documents quotes
  them. The owner's cap is 20 € per month and store fees are not approved yet.
- **iOS** can be tested only occasionally (borrowed iPhone) and not at all on real devices until the Apple
  fee is approved. Say so in every summary where it matters.

## 9. What "finished" looks like for the beta

A parent opens a link, signs in with a code, asks to join, is approved, gets a notification for the next
training, slides to answer, and the coach — who created the team and a season of trainings in a few minutes —
sees the number change, reminds the rest with one button, takes the register in seconds, posts an
announcement and shares the season calendar as a document. In three languages, on Android, iPhone and web,
with nothing on screen that does not work and no way for one team to see another's data.
