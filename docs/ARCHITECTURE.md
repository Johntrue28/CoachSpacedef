# CoachSpace — Architecture

> Technology choices and how the code is organised. Short on purpose: update it when a rule changes.
> Status: the app framework is in place; the backend is **proposed and not set up**.

## 1. Choices

| Layer | Choice | Status | Why | Cost |
|---|---|---|---|---|
| App (iOS, Android, web) | **Expo SDK 58, React Native, Expo Router, TypeScript** | In place | One code base for the three platforms; push notifications and store builds are supported | Free to develop |
| Backend | **Supabase** (PostgreSQL, sign-in, file storage, row-level security) in an EU region | Proposed | Database, accounts, permissions and files in one service; access rules enforced in the database | Has a free plan; current limits to be checked before setup |
| Builds and store submission | Expo Application Services (EAS) | Later | Builds iOS and Android in the cloud | Has a free plan; to be checked |
| Stores | Apple Developer Program, Google Play Console | Later | Needed to install a beta on real iPhones and to publish | 99 $ per year; 25 $ once |
| Code and CI | GitHub, GitHub Actions | In place | Version history; checks on every pull request | Free |
| Design | Penpot | Not started | Free; the owner cannot pay for Figma | Free |

Trade-off accepted: the web version made with Expo is less flexible than a separate website. If a marketing
site or a club back-office is needed later, it can be a separate project.

Not chosen: a separate Next.js web app (two code bases to keep in step), a web app wrapped as a native app
(feels like a website, weaker notifications), separate Swift and Kotlin apps (two apps to build).

## 2. Folders

```text
src/app/        Screens. Every file is a route (Expo Router). Only screens and layouts live here.
assets/         App icon, splash image, favicon (template placeholders until the brand exists)
docs/           PRODUCT, RESEARCH, ARCHITECTURE, ROADMAP, DECISIONS
.github/        CI workflow
```

Folders to add when they are first needed, not before: `src/components/` (reusable interface pieces),
`src/features/<area>/` (code for one product area), `src/domain/` (rules with no interface, with unit tests),
`src/lib/` (Supabase client and other services), `supabase/` (database migrations and access-rule tests).

## 3. Rules

- **Rules outside the interface.** Business rules (who can answer for whom, how a register is pre-filled) are
  plain TypeScript functions with unit tests, so screens stay thin.
- **Access is enforced in the database.** Hiding a button is never the protection. Every table gets
  row-level security, and the rules are tested between different coaches, teams, players and guardians.
- **No secrets in the app.** Only the public Supabase URL and anonymous key reach the client.
- **Separate environments.** A development Supabase project from the start; production only with the owner's
  approval.
- **Design tokens** (colours, type, spacing) come from the approved design and live in one place. Screens do
  not use raw colour values.

## 4. Checks

`npm run check` runs the linter, the TypeScript check and a web build; CI runs the same. Unit tests, access-rule
tests and end-to-end tests are added with the first feature that needs them (see `ROADMAP.md`).

## 5. Known limits

- The linter and its Expo preset were installed with npm because the Expo installer could not reach its
  compatibility service; versions match Expo SDK 58.
- Only the web build has been run so far. iOS and Android have not been run on a simulator or a device.
