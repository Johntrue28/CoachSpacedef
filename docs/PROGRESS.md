# CoachSpace — Progress

> The single place that says what is done, what is in progress and what is next. **Update it at the end of
> every working session**, before the summary to the owner. Keep it short: facts, not narrative.

## Now

| | |
|---|---|
| Current phase | **0 — Foundation hardening** (not started) |
| Waiting on the owner | Create the Supabase project (`SETUP_SUPABASE.md` §1) — blocks phase 1, not phase 0 |
| Branch | `claude/eager-bohr-jyxsbp` (no pull request open; `main` has only the first skeleton) |
| Last verified | 15 Nov 2026: `npm run check` passes; database tests pass (108 checks) on local PostgreSQL 16; web app looked at in a browser at phone size |

## Phases

Status: ☐ not started · ◐ in progress · ☑ done (owner approved) · ⏸ blocked

| Phase | Status | Notes |
|---|---|---|
| 0 Foundation hardening | ☐ | |
| 1 Backend bring-up and sign-in | ⏸ | Needs the Supabase project |
| 2 Teams, joining, roster | ☐ | |
| 3 Events, availability, Home, Calendar | ☐ | |
| 4 Notifications and reminders | ☐ | |
| 5a Register · 5b Announcements · 5c Chat · 5d Documents | ☐ | |
| 6 Beta readiness | ☐ | Needs O-005, O-010, O-011, O-012 |
| 7a Statistics · 7b Notes · 7c Lifts · 7d Tasks · 7e Squad · 7f Polls | ☐ | Checkpoint mid-January |
| 8 Coach Pro | ☐ | |
| 9 Beta | ☐ | |

## What exists today (audit of 15 November 2026)

| Area | State | Detail |
|---|---|---|
| Design tokens, fonts, icons | Done | `src/theme/`; mirrors Penpot. Fonts are imported from the package index (to fix in phase 0) |
| Base components | Done | `Text`, `Touchable`, `Button`, `Tag`, `Avatar`, `AnswerBadge`, `AnswerStats`, `Divider`, `EventRow`, `PersonRow`, `Section`, `Screen`, `ScreenHeader`, `StateView`, `TopBar`, `TabBar` |
| Missing components | To build with their features | Slide to answer, segmented switch, form field, sheet, toggle pair (register), menu row, unread dot |
| Translations | Partial | English and Spanish; no Dutch; choice not remembered; contains obsolete `reason.*` keys |
| Navigation | Partial | Five tabs and the event screen. No sign-in, no team switcher, no stack screens besides Event |
| Screens on example data | Partial, coach only | Home (no bell, no "Needs you", no announcement), Calendar (list only), Event (who's coming + remind), Team (players only), Chat (no announcements, no delete), More (language only) |
| Player and guardian views | Missing | Nothing role-aware yet |
| Data layer | Starting point | One `Repository` interface, in-memory implementation, hand-made `useQuery`; contains `AbsenceReason` (obsolete) |
| Domain rules | Partial | Totals, initials, formatting, countdown. No tests |
| Database | Written, tested locally, **not applied anywhere** | 4 migrations, 35 tables, 108 access checks, CI job |
| Backend services | Missing | No Supabase project, no sign-in, no notifications, no files |
| Tests | Database only | No unit, component or end-to-end tests |
| CI | Lint, types, web build, database tests | |
| Builds | Web only | iOS and Android never run |
| Preview | Manual | A private preview page made by hand on 15 Nov (it will go stale); a permanent preview host is a phase 0 task |
| Penpot | 17 phone screens, 8 components, 23 icons | Updates listed in `UX_SPECIFICATION.md` §7 |

## Session log (newest first; one or two lines each)

| Date | Who | What |
|---|---|---|
| 2026-11-15 | Fable (architect) | Product definition closed: nine documents, four migrations with tests, audit, handoff. |
| 2026-11-15 | Fable | App foundation and first coach screens on example data (D-012). |
| 2026-11-15 | Fable | Penpot: tokens, components, 17 phone screens. |

## Open questions for the owner

See `DECISIONS.md` §2 (O-003, O-004, O-005, O-010, O-011, O-012).
