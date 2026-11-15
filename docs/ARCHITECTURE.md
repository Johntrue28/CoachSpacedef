# CoachSpace — Architecture

> Technology choices and how the code is organised. Short on purpose: update it when a rule changes.
> Status: the app foundation and the first coach screens are in place, on fictional data; the backend is
> **proposed and not set up**.

## 1. Choices

| Layer | Choice | Status | Why | Cost |
|---|---|---|---|---|
| App (iOS, Android, web) | **Expo SDK 58, React Native, Expo Router, TypeScript** | In place | One code base for the three platforms; push notifications and store builds are supported | Free to develop |
| Backend | **Supabase** (PostgreSQL, sign-in, file storage, row-level security) in an EU region | Proposed | Database, accounts, permissions and files in one service; access rules enforced in the database | Has a free plan; current limits to be checked before setup |
| Builds and store submission | Expo Application Services (EAS) | Later | Builds iOS and Android in the cloud | Has a free plan; to be checked |
| Stores | Apple Developer Program, Google Play Console | Later | Needed to install a beta on real iPhones and to publish | 99 $ per year; 25 $ once |
| Code and CI | GitHub, GitHub Actions | In place | Version history; checks on every pull request | Free |
| Design | Penpot | In use | Free; the owner cannot pay for Figma | Free |

Trade-off accepted: the web version made with Expo is less flexible than a separate website. If a marketing
site or a club back-office is needed later, it can be a separate project.

Not chosen: a separate Next.js web app (two code bases to keep in step), a web app wrapped as a native app
(feels like a website, weaker notifications), separate Swift and Kotlin apps (two apps to build).

## 2. Folders

```text
src/app/            Screens. Every file is a route (Expo Router). Only screens and layouts live here.
src/components/ui/  Reusable interface pieces (Button, Tag, EventRow, TabBar...), one per Penpot component
src/theme/          Design tokens (colours, spacing, type styles) and the bundled fonts
src/i18n/           Interface texts: en.ts (source) and es.ts (must have the same keys)
src/data/           Data shapes, the Repository interface, and the fictional data in data/demo/
src/domain/         Rules and formatting with no interface (answer totals, countdown, dates)
src/features/       Code for one product area shared by several screens (events)
src/hooks/          Shared React hooks (loading data, current time)
assets/             App icon, splash image, favicon (template placeholders until the brand exists)
docs/               PRODUCT, RESEARCH, DESIGN, ARCHITECTURE, ROADMAP, DECISIONS
.github/            CI workflow
```

Folders to add when they are first needed, not before: `src/lib/` (Supabase client and other services),
`supabase/` (database migrations and access-rule tests).

### How a screen gets its data

```text
screen  ->  useQuery(...)  ->  repository (src/data/index.ts)  ->  today: demoRepository (in memory)
                                                                  later: a Supabase implementation
```

Screens only know the `Repository` interface. Replacing the fictional data with the real backend means
writing one new implementation and changing one line in `src/data/index.ts`; screens do not change.

### How to change the look

Change a value in `src/theme/tokens.ts` (it mirrors the Penpot tokens) and every screen follows. Change a
component in `src/components/ui/` and every screen that uses it follows. Screens contain no raw colours.

## 3. Rules

- **Rules outside the interface.** Business rules (who can answer for whom, how a register is pre-filled) are
  plain TypeScript functions with unit tests, so screens stay thin.
- **Access is enforced in the database.** Hiding a button is never the protection. Every table gets
  row-level security, and the rules are tested between different coaches, teams, players and guardians.
- **No secrets in the app.** Only the public Supabase URL and anonymous key reach the client.
- **Separate environments.** A development Supabase project from the start; production only with the owner's
  approval.
- **Design tokens** (colours, type, spacing) come from the approved design and live in `src/theme/tokens.ts`.
  Screens do not use raw colour values.
- **No hard-coded interface text.** Every text comes from `src/i18n/`; TypeScript fails if a key is missing
  in Spanish.
- **Every pressable control is built on `Touchable`**, which gives the pressed feedback and the keyboard
  focus ring.

## 4. Checks

`npm run check` runs the linter, the TypeScript check and a web build; CI runs the same. Unit tests, access-rule
tests and end-to-end tests are added with the first feature that needs them (see `ROADMAP.md`).

## 5. Known limits

- Packages were installed with npm because the Expo installer could not reach its compatibility service.
  Versions of Expo modules were taken from the list bundled with Expo SDK 58; run `npx expo install --check`
  on the owner's Mac to confirm.
- No unit tests yet for `src/domain/`; they come with the first rule that carries risk (see §4).
- The language choice is not remembered after a restart; nothing is stored on the device yet.
- Only the web build has been run so far. iOS and Android have not been run on a simulator or a device.
