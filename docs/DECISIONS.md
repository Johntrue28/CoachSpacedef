# CoachSpace — Decisions

> Decisions made by the owner, with the alternatives and the reason. Add new ones at the end.
> A recommendation is not a decision: open questions stay in §2 until the owner decides.

## 1. Decided

| # | Date | Decision | Alternatives | Reason |
|---|---|---|---|---|
| D-001 | 2026-11-10 | The product is rebuilt from scratch in this repository. The old demo is a read-only reference; no code is carried over. | Evolve the demo | The demo was a browser-only simulation with a data model unfit for real use, and its look and hidden functions disappointed the owner. |
| D-002 | 2026-11-12 | Reference product: TeamPlus. Target users: coaches and amateur clubs, team sports first, one structure for all sports. | Independent tennis coaches first | All replies to the outreach came from team-sport clubs; the owner knows team sport first-hand. |
| D-003 | 2026-11-12 | Matches and tournaments are in scope from the start, not only trainings. | Trainings only | Needed to match the reference product. |
| D-004 | 2026-11-15 | First version = levels 1 and 2 of `PRODUCT.md`. Level 3 (kitty, fines, treasurer, club panel, payments) comes later. | Level 1 only; everything at once | The owner wants a product complete enough to present to his club; level 3 depends on clubs using it. |
| D-005 | 2026-11-12 | The name is CoachSpace. Interface in English by default, Spanish selectable. New visual identity; visual references Nike, Strava, TeamPlus. Dark mode is not a priority. | Keep the demo's identity | Owner's preference. |
| D-006 | 2026-11-12 | Native app and web. Target: a beta in February 2027. Design is worked out with the owner before screens are built. | Web first | Competitors live on the phone; the owner prefers waiting for a native app. |
| D-007 | 2026-11-15 | Development starts: one Expo (React Native, TypeScript) code base for iOS, Android and web. | Separate Next.js web app; wrapped web app; Swift and Kotlin | One code base for one person to maintain. The owner gave the go-ahead to start after this was recommended; Supabase as backend is recommended but not yet set up (see O-002). |

## 2. Open

| # | Question | Recommendation |
|---|---|---|
| O-001 | Is chat in the first version? | No: costly to do well, and teams already use WhatsApp. |
| O-002 | Backend: Supabase in an EU region? | Yes; confirm when the free plan's current limits have been checked. |
| O-003 | Ads in the future? | No while minors use the app; revisit with legal advice. |
| O-004 | Plans and prices (coach plan, club plan) | Decide after the beta, with real usage. |
| O-005 | Monthly budget and the store fees (Apple 99 $ per year, Google 25 $ once) | Needed before M6. |
| O-006 | How guardians and children work in detail (who answers, from what age a child has an account) | Define in M1; design for a digital consent age of 16. |
