# CoachSpace

A team app for coaches and amateur sports clubs: trainings and matches in one calendar, players (or their
parents) answer whether they are coming, and the coach sees who is in, picks the squad and keeps the team's
documents in one place.

This repository is the **new** CoachSpace, rebuilt from scratch. The earlier demo
(`Johntrue28/CoachSpacedemo`) is a read-only reference and shares no code with this project.

**Status:** the product is defined and the database is written; the app has its foundation and first screens on
example data. See [`docs/PROGRESS.md`](docs/PROGRESS.md).

## Documentation

| File | Read it for |
|---|---|
| [`docs/HANDOFF_OPUS.md`](docs/HANDOFF_OPUS.md) | **Start here** if you are going to build: what, why, and where to begin |
| [`CLAUDE.md`](CLAUDE.md), [`AGENTS.md`](AGENTS.md) | Working rules; Expo-specific technical rules |
| [`docs/PRODUCT.md`](docs/PRODUCT.md) | What CoachSpace is, for whom, scope, roles |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Decision log and open questions |
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | What is done, in progress and next |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Milestones, timeline, what the owner needs to do |
| [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md) | Phases in build order with acceptance criteria |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Technology choices and how the code is organised |
| [`docs/DATABASE.md`](docs/DATABASE.md) | Data model, permissions, migrations |
| [`docs/UX_SPECIFICATION.md`](docs/UX_SPECIFICATION.md) | Navigation and screens per role |
| [`docs/FEATURE_SPECIFICATIONS.md`](docs/FEATURE_SPECIFICATIONS.md) | Every function in detail |
| [`docs/DESIGN.md`](docs/DESIGN.md) | Visual direction and design rules |
| [`docs/SETUP_SUPABASE.md`](docs/SETUP_SUPABASE.md) | External services: who sets up what |
| [`docs/RESEARCH.md`](docs/RESEARCH.md) | Evidence from clubs and competitors |

## Run it

Requires Node.js 22. From the project folder:

```bash
npm install
```

```bash
npm run web
```

`npm run ios` opens the iOS Simulator (needs a Mac with Xcode) and `npm run android` an Android emulator.

## Checks

```bash
npm run check
```

Runs the linter, the TypeScript check and a web build. CI runs the same on every pull request.

Database tests (need PostgreSQL 16 and permission to create a database):

```bash
supabase/tests/run.sh
```
