# CoachSpace

A team app for coaches and amateur sports clubs: trainings and matches in one calendar, players (or their
parents) answer whether they are coming, and the coach sees who is in, picks the squad and keeps the team's
documents in one place.

This repository is the **new** CoachSpace, rebuilt from scratch. The earlier demo
(`Johntrue28/CoachSpacedemo`) is a read-only reference and shares no code with this project.

**Status:** project foundation only. There are no product screens yet; see [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Documentation

| File | Read it for |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Working rules for AI assistants and contributors |
| [`AGENTS.md`](AGENTS.md) | Expo-specific technical rules (from the Expo template) |
| [`docs/PRODUCT.md`](docs/PRODUCT.md) | What CoachSpace is, for whom, and the scope of the first version |
| [`docs/RESEARCH.md`](docs/RESEARCH.md) | Evidence from clubs and the competitor research |
| [`docs/DESIGN.md`](docs/DESIGN.md) | Visual direction, design rules and interaction mechanics |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Technology choices and how the code is organised |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Milestones and what is being worked on now |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Decision log, including open decisions |

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
