# CoachSpace — Project rules

Rules for AI coding assistants and contributors. Technical Expo rules are in `AGENTS.md`; read both.

## People and language

- The product owner is the founder. He is not a programmer: he decides product, design and business; the
  assistant does the technical work and explains it.
- Talk to the owner in **Spanish**, in plain language.
- **The owner does not use the Terminal.** The assistant runs every command itself (git, installs, checks,
  running the app) and gives the owner a preview to open in the browser. If something truly needs the
  owner's Mac, Xcode or a physical device, explain exactly what and why, and look first for an alternative
  with clicks instead of commands.
- Code, comments, commit messages and documentation are in **English**.
- The app's interface is English by default, with Spanish and Dutch selectable. No hard-coded interface text.

## Roles (D-014)

- **Architect (Claude Fable):** product definition, architecture, data model and these documents.
- **Implementer (Claude Opus):** builds, tests and fixes, phase by phase. Start at `docs/HANDOFF_OPUS.md`.
- Technical choices inside what is documented need no approval from the owner. Product or scope changes,
  anything that costs money, production, store submissions and destructive operations do.

## Two repositories

- `Johntrue28/CoachSpacedef` (this one) is the only place where development happens.
- `Johntrue28/CoachSpacedemo` is the old demo: **read-only**. Never modify it and never copy its code or
  components here. Ideas may be reused after the owner agrees.

## How to work

- Read `docs/HANDOFF_OPUS.md` first; it lists the other documents in reading order. The documents are the
  source of truth; if code and documents disagree, say so before changing either.
- One phase at a time (`docs/IMPLEMENTATION_PLAN.md`), in small slices. Do not start the next phase without
  the owner's go-ahead. Update `docs/PROGRESS.md` at the end of every session.
- **Design before screens.** Screens are composed from the approved design system (tokens and components)
  following `docs/UX_SPECIFICATION.md`. A new visual pattern is shown to the owner before it spreads (A-012).
  Do not invent a visual identity in code.
- A feature goes in only if it is in the scope in `docs/PRODUCT.md`. Propose additions; do not add them.
- Every visible control must work. No "coming soon" controls.
- Record every significant decision in `docs/DECISIONS.md`: the owner's in the D- table, technical ones he
  delegated in the A- table. Never record as the owner's a decision he has not made.
- Never invent research, customer feedback, prices or statistics.

## Safety

- Never commit secrets. Local secrets live in `.env.local` (ignored by Git); only variable names go in
  `.env.example`. Never put a Supabase service-role key in the app.
- No paid service, subscription, production deployment or store submission without the owner's explicit
  approval.
- No destructive database operation without the owner's explicit approval. Development and production are
  separate environments.
- No real personal data in tests, seeds or documents; example data is invented and needs no "fictional"
  label (D-030). The app will hold minors' data: collect the minimum,
  and enforce access rules in the database, not only in the interface.

## Git

- Work on a branch, open a pull request when asked, keep `main` deployable. No force-push to shared branches.

## Before finishing a task

Run `npm run check` and the database tests (`supabase/tests/run.sh`), and look at the running app, not only
the code. Then tell
the owner, in Spanish: what changed, which files, which checks ran and their results, what is unverified,
and what he needs to do (decisions and clicks, never Terminal commands).
