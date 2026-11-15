# CoachSpace — Setting up Supabase and the other services

> What has to exist outside the repository, who does each step and how. The owner's steps are clicks in a
> browser; everything with commands is done by Claude. Nothing here costs money unless it says so.
> Screens of these services change: if a name below does not match what you see, the implementer reads the
> service's current documentation instead of guessing.

## 1. Supabase — development project

### Owner (about ten minutes, once)

1. Go to supabase.com and create an account (signing in with GitHub is the quickest).
2. Create an organisation if asked (free plan).
3. Create a **new project**:
   - Name: `coachspace-dev`
   - Database password: let Supabase generate one and **save it in your password manager**.
   - Region: one in the **European Union** (for example Frankfurt).
   - Plan: Free.
4. Tell Claude the project is ready. Claude will then ask, through a secure form (never in the chat), for:
   - the project's address and its public key (these are not secret, but the form avoids copy mistakes);
   - an access token for your Supabase account (created under your account settings) so Claude can apply the
     database definition;
   - the database password from step 3.
5. If Claude reports that the network of its environment blocks the Supabase address, approve the change it
   proposes (one click).

### Implementer (Claude), after the owner's steps

1. Read Supabase's current documentation for the CLI and for anything used below.
2. Link the project and apply the migrations in order (`supabase/migrations/`). No Docker is needed to push
   migrations to a hosted project.
3. Run `supabase/setup/after_migrations.sql` in the SQL editor or through the CLI (enables live updates for
   chat and answers, and schedules the automatic reminders; the scheduler extension must be enabled first).
4. **Sign-in settings:** enable email sign-in with one-time codes; set the code length to six digits; edit the
   email template so that it shows the code (`{{ .Token }}`) and not only a link; write the template in
   English, Spanish and Dutch in one email (the service has one template). Keep "confirm email" consistent
   with code sign-in.
5. **Allowed addresses:** add the preview host and, later, the domain to the allowed redirect addresses.
6. Check that the storage bucket `team-documents` exists and is private (migration 4 creates it).
7. Generate TypeScript types into `src/data/supabase/database.types.ts`.
8. Put only the **public** values in the app's environment: `EXPO_PUBLIC_SUPABASE_URL`,
   `EXPO_PUBLIC_SUPABASE_ANON_KEY`. Names go in `.env.example`; values in `.env.local` (ignored by Git), in the
   preview host's settings and in EAS environment variables.
9. Read the free plan's current limits (project pausing after inactivity, database and file size, email
   sending rate) and write the ones that matter into `ARCHITECTURE.md` §12 with the date checked.
10. Create two test accounts with invented names and run the integration script.

**Never** put the service-role key or the database password in the app, in Git or in a preview host. They
live only in the Claude environment's secrets and in Supabase function secrets.

### Granting Coach Pro by hand (beta)

In the SQL editor of the project, for the account's id:

```sql
insert into public.entitlements (user_id, feature, source) values ('<user id>', 'library', 'beta');
```

### Erasing a removed player's history on request

A destructive operation: only with the owner's explicit approval, in the SQL editor, for one member id:

```sql
delete from public.members where id = '<member id>' and left_at is not null;
```

Answers, attendance, squad places and lift seats of that member are deleted with it.

## 2. Supabase — production project

Created in phase 6, **only with the owner's approval**, as a separate project (`coachspace`), same region,
same steps. Migrations are applied to development first, then to production. No test data in production.

## 3. Expo (EAS)

| Step | Who |
|---|---|
| Create a free Expo account at expo.dev | Owner (clicks) |
| Give Claude access: an access token through the secure form | Owner (clicks) |
| Link the project to the account, configure build profiles and environment variables | Implementer |
| Android test builds: installable from a link or QR, no store account needed | Implementer builds; owner installs |
| iOS test builds: need the Apple Developer Program (O-005); until then iPhones use the web version | — |

## 4. Preview hosting (authorised, D-028)

The web build is published to a free static host so the owner has a permanent link for each delivery.
The implementer picks the simplest free option that needs the fewest accounts (EAS Hosting, since an Expo
account is needed anyway; otherwise Vercel), checks its free limits, and sets it up. Previews are not a public
product site: no search indexing, and the example-data build by default.

## 5. Stores (not approved yet, O-005)

| Service | Cost | Needed for |
|---|---|---|
| Apple Developer Program | 99 $ per year | TestFlight, any installation on iPhones, push notifications on iOS |
| Google Play Console | 25 $ once | Testing tracks and publishing on Google Play (test builds by link work without it) |

When approved: the owner creates each account (identity checks can take days — start early), then gives
Claude access through the services' own invitation or key mechanisms.

## 6. Later

| Thing | When |
|---|---|
| Domain name (O-010) | Before the beta: invitation links that open the app; sender address for emails |
| Email sending service | Only if Supabase's built-in email limits block sign-in for real users; needs the owner's approval if it costs |
| Privacy notice and terms (O-011) | Before the beta; shown at sign-in and in Your account |

## 7. What is configured where (keep this table true)

| Setting | Where | Status |
|---|---|---|
| Supabase development project | supabase.com | Not created |
| Migrations applied to development | — | No |
| `after_migrations.sql` run on development | — | No |
| Email code template | Supabase dashboard | No |
| Public app variables | `.env.local`, preview host, EAS | No |
| Secrets (access token, database password) | Claude environment secrets | No |
| Expo account and project link | expo.dev | No |
| Preview host | — | No (a manual preview page exists: see `PROGRESS.md`) |
| Apple / Google accounts | — | Not approved |
| Production project | — | Not created |
