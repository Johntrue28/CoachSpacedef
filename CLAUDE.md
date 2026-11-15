# CoachSpace — Project rules

Rules for AI coding assistants and contributors. Technical Expo rules are in `AGENTS.md`; read both.

## People and language

- The product owner is the founder. He is not a programmer: he decides product, design and business; the
  assistant does the technical work and explains it.
- Talk to the owner in **Spanish**, in plain language. Give exact commands and say where to run them.
- Code, comments, commit messages and documentation are in **English**.
- The app's interface is English by default with Spanish selectable. No hard-coded interface text once
  translations are set up.

## Two repositories

- `Johntrue28/CoachSpacedef` (this one) is the only place where development happens.
- `Johntrue28/CoachSpacedemo` is the old demo: **read-only**. Never modify it and never copy its code or
  components here. Ideas may be reused after the owner agrees.

## How to work

- Read `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md` and `docs/DECISIONS.md` before a
  substantial task. They are the source of truth; if code and documents disagree, say so before changing either.
- One milestone at a time, in small steps. Do not start the next milestone without the owner's go-ahead.
- **Design before screens.** Product screens are built only from a design the owner has approved. Do not
  invent a visual identity in code.
- A feature goes in only if it is in the scope in `docs/PRODUCT.md`. Propose additions; do not add them.
- Every visible control must work. No "coming soon" controls.
- Record every significant decision in `docs/DECISIONS.md`. Never record a decision the owner has not made.
- Never invent research, customer feedback, prices or statistics.

## Safety

- Never commit secrets. Local secrets live in `.env.local` (ignored by Git); only variable names go in
  `.env.example`. Never put a Supabase service-role key in the app.
- No paid service, subscription, production deployment or store submission without the owner's explicit
  approval.
- No destructive database operation without the owner's explicit approval. Development and production are
  separate environments.
- No real personal data in tests, seeds or documents. The app will hold minors' data: collect the minimum,
  and enforce access rules in the database, not only in the interface.

## Git

- Work on a branch, open a pull request when asked, keep `main` deployable. No force-push to shared branches.

## Before finishing a task

Run `npm run check` (lint, typecheck, web build) and look at the running app, not only the code. Then tell
the owner, in Spanish: what changed, which files, which checks ran and their results, what is unverified,
and what he needs to do.
