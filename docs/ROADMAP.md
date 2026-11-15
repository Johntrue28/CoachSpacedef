# CoachSpace — Roadmap

> Where the project is and what comes next, for the owner. The detailed plan per phase is in
> `IMPLEMENTATION_PLAN.md`; the live status of every task is in `PROGRESS.md`.
> **Target:** a beta used by the owner's club in February 2027.

## Milestones

| # | Milestone | Status |
|---|---|---|
| M0 | **Foundation:** repository, Expo project, checks, CI | Done |
| M1 | **Product definition:** scope, roles, flows, data model, architecture, specifications, plan | Done (15 November 2026) |
| M2 | **Design in Penpot:** direction, tokens, components, 17 phone screens | Done for the key screens; small updates listed in `UX_SPECIFICATION.md` §7 |
| M3 | **Backend:** Supabase development project, migrations applied, sign-in | Migrations written and tested locally. **Waiting for the owner to create the Supabase project** (phase 1) |
| M4 | **Level 1 build** (phases 0–5) | Started: app foundation and first coach screens on example data |
| M5 | **Beta readiness** (phase 6) | Not started |
| M6 | **Level 2 build** (phase 7) | Not started |
| M7 | **Coach Pro** (phase 8) | Not started |
| M8 | **Beta** with the owner's club (phase 9) | Not started |

## Timeline (a plan, not a promise)

| When | What |
|---|---|
| November 2026 | Phases 0–1: foundation hardening, backend, sign-in |
| December 2026 | Phases 2–3: teams and joining; events, answers, Home, Calendar |
| Early January 2027 | Phases 4–5: notifications; register, announcements, chat, documents |
| **Mid-January 2027** | **Checkpoint with the owner:** what of level 2 ships in the beta |
| Late January 2027 | Phase 6 (beta readiness) and phase 7 slices |
| February 2027 | Beta |

## What the owner needs to do, and by when

| What | Why | By |
|---|---|---|
| Create a Supabase account and the development project (`SETUP_SUPABASE.md`, about ten minutes of clicks) | Nothing real can be built without it | Now |
| Create an Expo account (free) | Preview links and phone builds | Phase 0 |
| Decide the store fees: Apple 99 $ per year, Google 25 $ once (O-005) | iPhone testing and the beta on real phones | 10 January 2027 |
| Find a native Dutch speaker to review the texts (O-012) | Dutch is the club's language | January 2027 |
| A domain name (O-010) | Invitation links that open the app | January 2027 |
| Privacy notice and who is responsible for the data (O-011) | Required before real users and by the stores | Before the beta |
| Review each delivery in the preview and say what to change | The owner approves each phase | Every phase |

## Honest risks

- **Scope against time.** All of level 1 and level 2 by February (D-016) is ambitious for one reviewer and a
  product not yet used by anyone. Level 1 is built first and is never cut; level 2 arrives in independent
  slices so that whatever is ready can ship.
- **iPhone.** Without the Apple fee, iPhones can only use the web version and get no notifications; with a
  borrowed iPhone only occasionally available, iOS problems will be found late.
- **Free plans.** The 20 € monthly cap relies on free tiers whose limits have not been checked yet; they are
  checked when each service is set up.
- **Nothing is validated with real users** until the beta. The first weeks of the beta may change priorities.
- **Legal.** No entity exists and the app will hold minors' names. This is a gate for the beta, not a detail.
