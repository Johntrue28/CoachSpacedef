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
| D-008 | 2026-11-15 | Team chat is in the first version (level 1). | Leave chat out and rely on WhatsApp (the assistant's recommendation) | Owner's decision: the reference product has it. Cost accepted: chat is one of the more expensive parts to build well. |
| D-009 | 2026-11-15 | Visual direction: "Matchday" (black, white, one accent; heavy condensed display type; square corners), with modern interaction mechanics in the spirit of Nike and Strava. Rules in `DESIGN.md`. | "Clubhouse" (warm, rounded); "Scoreboard" (blue, cards) | The owner found it the most developed and the least generic; he asked for little rounding. |
| D-010 | 2026-11-15 | Design requirements for identity, typography, spacing, components, accessibility, navigation, data, responsive behaviour and quality, as listed in `DESIGN.md` §2. | — | Set by the owner as the standard every screen must meet. |
| D-011 | 2026-11-15 | No team streak or other streak feature. | A Strava-style team streak on the coach's home; an actionable alert instead | Owner's decision: the reference demo has none. |
| D-012 | 2026-11-15 | The phone screens drawn in Penpot are accepted as the base, and building the app in Expo starts now, on fictional data, structured so that the look and the data source can be changed later. Work is pushed to GitHub as it goes. | Finish every design and the backend first | Owner's request: see it running early and be able to correct it. Screens not yet designed are still not built. |
| D-013 | 2026-11-15 | Working method: the owner does not use the Terminal; the assistant runs everything and provides a browser preview. | — | Owner's instruction: he is the founder, not the developer. |
| D-014 | 2026-11-15 | Roles in the project: Claude Fable defines product and architecture and keeps the documentation; Claude Opus implements from `HANDOFF_OPUS.md`. | — | Owner's instruction. |
| D-015 | 2026-11-15 | The exercise library, training plans and assigned exercises are in the product as a **paid feature (Coach Pro)**. They are designed in the data model now and built after the core. | Out of scope (earlier draft of `PRODUCT.md`); in the free product | Owner's decision. It reverses the earlier exclusion; the club feedback ("too advanced") is respected by keeping it a coach-only, optional module. |
| D-016 | 2026-11-15 | The February beta aims at **all of level 1 and level 2**. | Level 1 only (the assistant's recommendation); level 1 plus lifts and statistics | Owner's decision. Risk recorded in `ROADMAP.md`: level 1 is built first and is never cut; a checkpoint in mid-January decides what level 2 parts ship in the beta. |
| D-017 | 2026-11-15 | Chat: one team chat and announcements only. No private chats in the first version. | Private chats that always include the guardian; free private chats | Protection of minors. |
| D-018 | 2026-11-15 | Under 16: no account; a guardian answers. From 16: own account. The age is declared at joining; no birth date is stored. | Under-16 accounts authorised by a guardian (kept possible in the model for later) | Simplest safe start; minimum data. |
| D-019 | 2026-11-15 | Joining: by link, and a coach approves each request. | Anyone with the link enters directly | A forwarded link must not give access to minors' data. |
| D-020 | 2026-11-15 | Backend: Supabase in an EU region, free plan to start. The owner answered the confirmation question by repeating the recommendation; it is confirmed in practice when he creates the project. | Firebase; own server | Database, accounts, row-level permissions and files in one service. |
| D-021 | 2026-11-15 | Budget: at most 20 € per month for services during the beta. Store fees not yet approved. Devices available: Mac and Android; an iPhone can sometimes be borrowed. | — | Owner's answer. |
| D-022 | 2026-11-15 | Answers are **in / out** only. No "maybe". | In / maybe / out, as in the demo | The coach needs a number. |
| D-023 | 2026-11-15 | **Slide to answer** is in, with a button alternative for accessibility. | Two buttons only | Owner approved the mechanic (closes O-007). |
| D-024 | 2026-11-15 | **No reason for absence.** "Out" is a single tap. | A fixed list of reasons (drawn in Penpot as a proposal) | Owner's decision (closes O-009). The reason sheet in Penpot is obsolete. |
| D-025 | 2026-11-15 | Text typeface: **Inter Tight**. | Inter | Closes O-008. |
| D-026 | 2026-11-15 | Languages: English (default), Spanish and **Dutch**. | English and Spanish only | The beta club is in Groningen. Dutch texts need a native review before the beta. |
| D-027 | 2026-11-15 | Web in the beta uses the phone layout in a centred column; a desktop layout for coaches comes later. | Desktop layout first | Owner agreed. |
| D-028 | 2026-11-15 | A free hosting for preview links is authorised (no public production site). | Manual preview pages | Owner's authorisation. |
| D-029 | 2026-11-15 | From the demo, these come back: notes from last time, the latest announcement pinned on Home, a month view of the calendar, the attendance log. These do not: private chats, the central "+" button, photographs on cards. | — | Owner accepted the recommendations. |
| D-030 | 2026-11-15 | Example data (seeds, previews, screenshots) uses invented clubs, teams and people, and does not need to be labelled as fictional. | Label every example as fictional | Owner's instruction. Real personal data is still never used. |
| D-031 | 2026-11-15 | Legal: no entity exists yet; the privacy notice and the question of who is responsible for the data are settled later, before real users. | — | Owner's answer. Recorded as a gate in `ROADMAP.md`. |

### Decisions taken by the architect (the owner delegated them; he can overturn any)

| # | Decision | Reason |
|---|---|---|
| A-001 | A **team** is the single unit (a club team, a coach's group, a team of friends). It may belong to a club. Clubs exist in the data model from the start; their panel is level 3. | One structure for every case; no rebuild later. |
| A-002 | Any coach creates a team on their own; a club is optional. | Lowest friction (principle 1). |
| A-003 | Sign-in is a six-digit code sent by email. No passwords, no SMS (it costs money), no social sign-in in the first version. | Friction and budget. |
| A-004 | Events ask for an answer as soon as they exist. There is no "not sent yet" state. | Fewer things to manage; the Penpot text "not sent yet" is obsolete. |
| A-005 | Recurring trainings are real events created up to a year ahead; edits apply to "this event" or "this and following". | Simple rules and simple permissions. |
| A-006 | Answers close when the event starts; from then on the register is the record. | One source of truth. |
| A-007 | Notifications: push, plus an in-app list. Email only for the sign-in code. No push for chat messages in the first version (unread mark only). | Avoid noise; "works next to WhatsApp". |
| A-008 | One automatic reminder per event to those who have not answered, 24 hours before by default (the coach can change the hours or switch it off), plus the manual "Remind" button, at most once an hour. | Players answer without the coach chasing. |
| A-009 | No profile photos, no images in chat; avatars are initials. | Minors. |
| A-010 | No offline editing: the last loaded data is shown, changes need a connection. | Cost; revisit after the beta. |
| A-011 | No billing code before the beta ends; Coach Pro is granted by hand through an entitlement record. | Nothing to sell until real use is seen. |
| A-012 | The design system (tokens and components) plus `UX_SPECIFICATION.md` is the approved design basis. New screens are composed from existing components and reviewed by the owner in the preview; a Penpot mock-up is made first only for a new visual pattern. | The owner asked not to approve every small decision; keeps "design before screens" for anything new. |
| A-013 | The in-memory example data stays as a second implementation of the data interface, used for automated interface tests and for previews without an account. | Keeps the interface honest and gives the owner a preview that needs no sign-in. |
| A-014 | Server state in the app is handled with TanStack Query on top of the data interface. | Caching, refetching and live updates without hand-written code. |
| A-015 | The database is tested on plain PostgreSQL with a small shim (`supabase/tests/`), locally and in CI. | Access rules are verified without needing Docker or a hosted project. |

## 2. Open

| # | Question | Recommendation | Needed by |
|---|---|---|---|
| O-003 | Ads in the future? | No while minors use the app; revisit with legal advice. | After the beta |
| O-004 | Prices of Coach Pro and of the club plan | Decide after the beta, with real usage. | After the beta |
| O-005 | Store fees: Apple Developer Program (99 $ per year) and Google Play Console (25 $ once) | Approve both. Without Apple's, iPhones can only use the web version, where push notifications are unreliable. | 10 January 2027 |
| O-010 | A domain name for invitation links and the web app | Buy one before the beta (price to be checked when buying); until then links use the preview hosting address. | January 2027 |
| O-011 | Who is responsible for the data (the founder, a company, the club), privacy notice and terms | Have a professional review a short notice before real users. | Before the beta |
| O-012 | Who reviews the Dutch texts | A native speaker from the club. | Before the beta |

Closed: O-002 (D-020), O-006 (D-018), O-007 (D-023), O-008 (D-025), O-009 (D-024).
