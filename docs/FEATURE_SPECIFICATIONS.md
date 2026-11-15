# CoachSpace — Feature specifications

> What each function does, in enough detail to build it without product decisions. Screens are in
> `UX_SPECIFICATION.md`, data and permissions in `DATABASE.md`. If a case is not covered here, choose the
> simplest behaviour that fits `PRODUCT.md` §4, write it down in this document and continue.
>
> Each feature lists: **Goal**, **Who**, **Flow**, **Data**, **Rules** (validations and permissions),
> **States and edge cases**, **Done when** (acceptance criteria) and **Needs** (dependencies).
> Roles: **C** coach and assistant coach, **P** player with an account, **G** guardian.

## Index

| Level | Features |
|---|---|
| 1 — Core | F-01 Sign in and account · F-02 Teams · F-03 Invite and join · F-04 Roster and roles · F-05 Events · F-06 Availability · F-07 Reminders · F-08 Register · F-09 Announcements · F-10 Chat · F-11 Documents · F-12 Notifications · F-13 Home · F-14 Calendar · F-15 Languages |
| 2 — Full team | F-16 Statistics · F-17 Squad · F-18 Polls · F-19 Lifts · F-20 Tasks · F-21 Coach notes |
| Coach Pro | F-22 Exercise library · F-23 Training plans · F-24 Assigned exercises |

---

## Level 1

### F-01 Sign in and account

- **Goal:** get in without a password and stay in.
- **Who:** everyone.
- **Flow:** email → "Send me the code" → six-digit code from the email → first time: "Your name" → continue to
  the invitation being followed, to the team, or to Start. Later launches open straight into the app.
- **Data:** `auth.users`, `profiles` (`display_name`, `language`).
- **Rules:** email must look like an email; code is six digits; name 1–80 characters. The profile language
  starts as the app's current language and follows it when changed.
- **States and edge cases:** wrong or expired code → "That code is not right. Check it or ask for a new one";
  "Send again" enabled after 30 seconds; too many attempts → the service's wait message in plain words; no
  connection; the app closed between email and code → the code screen is restored for that email; signing out
  removes the session and this device's push token.
- **Account screen:** change name; see email; leave the current team (F-04); delete account: confirmation
  sheet that says what is removed, then the server function deletes it (`DATABASE.md` §8). A person who is the
  only coach of a team with other members must make someone else coach or delete the team first.
- **Done when:** a new person reaches the app in under a minute with only an email; closing and reopening
  keeps them in; sign-out returns to Welcome; deleting the account removes the profile and signs out on every
  device at the next request.
- **Needs:** Supabase Auth with the code in the email template; Edge Function `delete-account`.

### F-02 Teams

- **Goal:** a coach has a working team in one step.
- **Who:** anyone creates a team; coaches change its settings.
- **Flow:** Start or team switcher → "Create a team" → name and sport → the team opens on Home (empty state).
- **Data:** `teams`, `members` (the creator as `coach`), `team_invites` (the member link); `create_team`.
- **Rules:** name 1–60; sport one of basketball, football, tennis, other; time zone taken from the device.
- **Settings (C):** name, sport, season start (date; statistics count from it), automatic reminder (off, or
  1–72 hours before; default 24), chat open to everyone or coaches only, invite a coach (creates a one-use
  link valid 7 days, shared with the system share sheet), reset the invitation link (the old one stops working).
- **Several teams:** the switcher lists every team the person belongs to in any role. The last opened team is
  remembered on the device. Every screen shows data of the current team only.
- **States and edge cases:** no team → Start; removed from the current team while using it → back to the
  switcher or Start with "You are no longer in <team>".
- **Done when:** creating a team takes two fields; the creator is its coach; a second team can be created and
  switched to; settings changes show at once for other members after a refresh.
- **Needs:** F-01.

### F-03 Invite and join

- **Goal:** join by link with the least effort, without giving access to whoever forwards the link.
- **Who:** C shares and approves; anyone with the link asks.
- **Flow (asking):** open the link → team name and sport → sign in if needed (F-01) → "Who are you?": player
  (16 or older) or parent/guardian (+ the child's first and last name) → "Ask to join" → Waiting screen.
  A guardian can ask again for another child.
- **Flow (approving):** coaches get a notification and a row on Home and Team → Join requests → Approve →
  "New player" or pick an existing roster player without account (the list shows them, best name match first)
  → done; or Reject. The requester is notified and, on approval, lands in the team.
- **Data:** `team_invites`, `join_requests`, `members`, `guardians`; `get_invite`, `request_to_join`,
  `decide_join_request`.
- **Rules:** a request gives no access until approved. A person already in the team as coach or player cannot
  ask as player again; they can always ask as guardian. Approving a player request attaches the account to the
  chosen roster entry (which must have no account). Approving a guardian request never attaches an account to
  the player. The player's declaration "16 or older" is the only age check.
- **States and edge cases:** invalid, revoked or used link → "This invitation is no longer valid. Ask your
  coach for a new link"; duplicate request → the Waiting screen of the existing one; request rejected → Start
  with a neutral message; the requester cancels a pending request; opening the link while already a member →
  the team opens.
- **Sharing (C):** "Share invite link" opens the system share sheet with the link and one line of text in the
  interface language. On the web it copies the link.
- **Done when:** a parent goes from link to "waiting" in under a minute; a coach approves in two taps and
  links a parent to a child already on the roster without creating a duplicate; a stranger with the link sees
  only the team's name until approved (covered by database tests).
- **Needs:** F-01, F-02, F-12 (notifications).

### F-04 Roster and roles

- **Goal:** the coach keeps the list of people true.
- **Who:** C manages; everyone sees names, numbers and positions.
- **Flow:** Team → Players. C: "Add player" (name; optional number and position) creates a roster entry
  without account — the usual way to load the team before anyone joins. C opens a player to edit, see
  guardians, unlink a guardian, or "Remove from team" (confirmation).
- **Roles:** the coach (not assistants) can make an assistant a coach or a coach an assistant, and remove a
  coach. A team always keeps one coach.
- **Data:** `members`, `guardians`; `leave_team`.
- **Rules:** name 1–80; number 0–999; position up to 40 characters, chosen from the sport's list with free
  text allowed (lists in `src/domain/sports.ts`: basketball — guard, forward, centre; football — goalkeeper,
  defender, midfielder, forward; tennis and other — none). Removing sets `left_at`: the person loses access at
  once and disappears from lists; past registers keep them.
- **Leaving:** a player or guardian leaves from Your account; a guardian leaving does not remove the child.
- **States and edge cases:** a player with an account and guardians (a 16-year-old whose parent also follows)
  is allowed: any of them answers, the last answer counts; two roster entries for the same child are merged by
  hand (remove one) — no merge tool in the first version.
- **Done when:** a coach can load a roster of 15 names in a few minutes; removed people lose access
  immediately (database test); the last coach cannot leave.
- **Needs:** F-02, F-03.

### F-05 Events

- **Goal:** schedule once; everyone sees it; change once.
- **Who:** C creates, changes and cancels; everyone sees.
- **Types:** training (may repeat weekly), match (opponent, home or away), tournament (name).
- **Flow (create):** Calendar **+** or Home empty state → form → "Create and ask the team". A repeating
  training asks for weekdays and an end date (default: end of the season, at most a year).
- **Flow (change):** Event → "…" → Edit → Save. For an event of a series: "This event" or "This and
  following" (the latter changes time, length and place only). Cancel → confirmation → "This event" or "This
  and following".
- **Data:** `events`, `event_series`; `create_event_series`, `update_following_events`,
  `cancel_following_events`.
- **Rules:** end after start; opponent or tournament name 1–80 for matches and tournaments, none for
  trainings; place up to 120; note up to 500; an event in the past can be created (to record attendance) but
  sends no notification. Changing one event of a series marks it as changed on its own, so later "this and
  following" edits skip it. A cancelled event keeps its answers and is shown as cancelled; it can be restored
  by editing it ("Restore event") while it is still in the future.
- **Notifications:** new event, time or place change, cancellation (F-12). A series announces once.
- **States and edge cases:** times are entered and shown in the device's time zone; series are built in the
  team's time zone so 18:00 stays 18:00 across clock changes; editing an event that already started is
  allowed only for the note; deleting is not offered — cancel instead (a mistaken event with no answers can be
  deleted from Edit: "Delete event").
- **Done when:** a weekly training for a season is created in one form; changing the time of one or of all
  following events notifies players once; cancelled events are clearly marked everywhere.
- **Needs:** F-02.

### F-06 Availability ("Are you coming?")

- **Goal:** the coach knows who is coming; answering takes one gesture.
- **Who:** P for themselves; G for each child; C for any player.
- **Flow:** on Home (next event) or on the Event: slide to answer "in", or press "I can't come". The answer
  block replaces the control; "Change answer" brings it back. Coaches press a player's row in Who's coming →
  sheet "In / Out / No answer".
- **Data:** `availability` (no row = no answer).
- **Rules:** allowed from creation until the event starts; the last answer counts; cancelled events take no
  answers. A coach clearing an answer deletes the row. Totals: in, out, no reply, over all active players.
- **Feel:** the answer shows at once (optimistic) and is rolled back with a message if the server refuses;
  haptic tick on success; the totals on the event update live for everyone looking at it.
- **States and edge cases:** guardian with two children in the team → one row per child, each with its own
  control; the event starts while the screen is open → control replaced by "Answers are closed"; a player
  removed from the team no longer counts.
- **Done when:** answering from a notification takes one tap to open and one gesture; the coach's totals
  change within a couple of seconds without refreshing; nobody can answer for a player they do not act for
  (database test).
- **Needs:** F-05; live updates.

### F-07 Reminders

- **Goal:** people answer without the coach chasing them one by one.
- **Who:** C triggers the manual one; the system sends the automatic one.
- **Flow:** the primary button "Remind N players" on Home and on the Event; after pressing: "Reminder sent ·
  14:05" in its place for an hour.
- **Data:** `event_reminders`, `notifications`; `remind_unanswered`, `queue_due_reminders`.
- **Rules:** a reminder goes to the accounts that can answer for players without an answer (the player, or
  their guardians). Manual: at most once an hour per event. Automatic: once per event, at the team's setting
  (default 24 hours before; off if disabled). N counts players, not accounts.
- **States and edge cases:** everyone answered → no button, "Everyone has answered"; a player without account
  and without guardian cannot be reminded: the Event lists them as "No account yet" under No reply so the
  coach knows to answer for them or invite the parent.
- **Done when:** the button's number matches the No reply list; pressing it twice within the hour is not
  possible; the automatic reminder arrives once.
- **Needs:** F-06, F-12; the scheduler.

### F-08 Register (attendance)

- **Goal:** the register takes seconds because it starts from the answers.
- **Who:** C.
- **Flow:** from the event's start time, the Event's primary button is "Take the register" → one row per
  player, pre-filled: answered in → here; answered out or no answer → absent → the coach flips who is
  different → "Save register". Afterwards the button reads "Edit the register".
- **Data:** `attendance`; `save_register`. The pre-fill rule is a pure function in `src/domain/` with tests.
- **Rules:** only after the start; every active player gets a row when saving; players who joined after the
  event are not included; editing later is allowed at any time.
- **Home:** "Register to take" appears under Needs you for events of the last 14 days that started and have
  no register.
- **States and edge cases:** cancelled event → no register; saving with no connection keeps the screen and
  offers retry.
- **Done when:** a register for 14 players with two corrections is saved in under 20 seconds; the pre-fill
  matches the rule; players see only their own attendance (database test).
- **Needs:** F-05, F-06.

### F-09 Announcements

- **Goal:** important one-way messages that do not scroll away.
- **Who:** C posts and deletes; everyone reads.
- **Flow:** Chat → Announcements → "New announcement" → title and text → "Post". The latest shows pinned on
  Home for everyone until dismissed (per device) or replaced by a newer one.
- **Data:** `announcements`, `read_state.announcements_seen_at`.
- **Rules:** title 1–80; text 1–2000; no editing (delete and post again); posting notifies everyone but the
  author.
- **Done when:** a posted announcement appears on every member's Home and notification list; deleting it
  removes it everywhere.
- **Needs:** F-12.

### F-10 Chat

- **Goal:** a team conversation for the teams that want one. Nothing else depends on it.
- **Who:** everyone in the team reads; everyone writes while the chat is open; only coaches when it is set to
  "coaches only". Children without an account are not in the chat; their guardians are.
- **Flow:** Chat → messages → type → send. Own message: long press → "Delete". Coaches: long press on any
  message → "Delete".
- **Data:** `messages`, `read_state.chat_seen_at`; `delete_message`; live updates.
- **Rules:** text only, 1–2000 characters, no editing; a deleted message stays as "Message deleted". New
  messages appear live; older ones load 50 at a time when scrolling up. No push notification for messages
  (A-007): an unread dot on the Chat tab instead.
- **States and edge cases:** sending without connection → the message shows as "Not sent · Try again";
  the chat switched to coaches only while typing → the composer is replaced and the draft is kept on screen
  until the person leaves.
- **Done when:** two people in the same team see each other's messages within a couple of seconds; a person of
  another team cannot read or write (database test); a coach can delete any message.
- **Needs:** F-02.

### F-11 Documents

- **Goal:** the files and links of the team, always findable.
- **Who:** C adds, renames, deletes; everyone opens.
- **Flow:** Team → Documents → **+** → "Upload a file" (system picker) or "Add a link" (title and address).
  Pressing a row opens the file (in the system viewer or a new tab) or the link.
- **Data:** `documents`, bucket `team-documents`.
- **Rules:** files up to 10 MB: PDF, JPEG, PNG, Word, Excel; links must start with `https://`; title 1–80
  (defaults to the file name without extension). Deleting a document deletes its file. List order: newest first.
- **States and edge cases:** upload progress and cancel; too large or wrong type → message before uploading;
  failed upload leaves no row; a file is opened through a link that expires after a few minutes.
- **Done when:** a coach uploads a PDF from the phone and a parent opens it; a person outside the team cannot
  open it even with the file's address (database test).
- **Needs:** F-02; storage.

### F-12 Notifications

- **Goal:** people learn what concerns them without opening the app, and can catch up inside it.
- **Who:** everyone.
- **What is sent:** the table in `DATABASE.md` §5.
- **Flow:** permission is asked once the person is in a team, with one sentence explaining why. A push opens
  the related screen. Home's bell opens the list; opening it marks everything as read.
- **Data:** `push_tokens`, `notifications`; Edge Function `send-push`.
- **Texts:** written per language from `type` and `data` — on the server for the push, in the app for the
  list. Examples: "New training · Thu 19 Nov 18:00", "Changed: Harbour U16 now starts at 10:30", "Are you
  coming? Training tomorrow 18:00", "Marta posted: Saturday", "Daan Bakker's parent asks to join".
- **Rules:** nobody is notified of their own action; a person in several teams gets the team's name in the
  text; permission refused → the list still works and Your account shows "Notifications are off" with a
  button to the system settings.
- **Done when:** each row of the table produces one push on a real Android phone and on an iPhone, in the
  person's language, and tapping it opens the right screen.
- **Needs:** F-01; a development build; the Expo push service.

### F-13 Home

- **Goal:** open the app and know what is next and what needs you.
- **Who:** everyone; contents differ by role (`UX_SPECIFICATION.md` §3).
- **Rules:** "next event" is the earliest scheduled event that has not ended; "Needs you" shows only real
  work (join requests and registers for coaches; unanswered events, open polls and a newly published squad for
  players and guardians) and disappears when empty; the pinned announcement follows F-09.
- **Done when:** with example data for each role, the first screen shows the next event, the right primary
  action and nothing the person cannot use.
- **Needs:** F-05 to F-09.

### F-14 Calendar

- **Goal:** see everything planned.
- **Who:** everyone; C creates from here.
- **Rules:** List shows upcoming events grouped by month, plus "Earlier" (collapsed) for the last 30 days;
  Month shows a grid starting on Monday with a mark per day that has events; the choice between List and Month
  is remembered on the device.
- **Done when:** a season of weekly trainings scrolls smoothly; the month grid marks the right days in every
  time zone.
- **Needs:** F-05.

### F-15 Languages

- **Goal:** each person uses the app in English, Spanish or Dutch.
- **Rules:** the first launch uses the device language if it is one of the three, otherwise English; the
  choice in More is remembered on the device and saved in the profile (it decides the language of push
  notifications). Dates and times follow the language. Content written by people is never translated.
- **Done when:** every screen is complete in the three languages with no missing or cut-off text at 320 px;
  the type check fails if a key is missing.
- **Needs:** a native review of the Dutch texts (O-012).

---

## Level 2

### F-16 Statistics

- **Goal:** attendance at a glance for the coach; each player sees only their own.
- **Who:** C sees everyone; P and G see their own.
- **Flow:** Team → Stats.
- **Data:** `attendance`; `attendance_summary`. Season = from the team's season start.
- **Rules:** attendance % = presences ÷ registers the player is in; team average = all presences ÷ all rows;
  events without a saved register do not count; cancelled events do not count. Shown as "86%" with "12 of 14".
  No ranking between players is ever shown to players or guardians.
- **Done when:** figures match a hand count on example data; a player cannot obtain anyone else's figure
  (database test).
- **Needs:** F-08.

### F-17 Squad

- **Goal:** tell the team who plays.
- **Who:** C picks and publishes; everyone sees once published.
- **Flow:** Event (match or tournament) → "Pick the squad" → each player: out, bench or starter (players who
  answered in are listed first; those who answered out are marked) → "Publish squad". Changes after publishing
  are saved at once and do not notify again.
- **Data:** `event_squads`, `squad_members`.
- **Rules:** only players of the team; no limit on numbers (sport-agnostic); unpublished squads are invisible
  to players. Publishing notifies players and guardians.
- **States and edge cases:** a called-up player later answers out → the coach's squad screen marks them
  "answered out"; removing the squad returns the event to "Pick the squad".
- **Done when:** a player sees "You are in the squad" only after publishing (database test).
- **Needs:** F-05, F-06, F-12.

### F-18 Polls

- **Goal:** quick team decisions.
- **Who:** C creates and closes; every account in the team votes once.
- **Flow:** Team → Polls → "New poll" → question, 2–10 options, one or several choices, optional closing date
  → post. Voting: press an option (again to withdraw); results show as counts and bars to everyone after they
  vote or once closed.
- **Data:** `polls`, `poll_options`, `poll_votes`; `create_poll`, `vote_in_poll`, `poll_results`.
- **Rules:** one vote per account (a guardian votes once, not per child); who voted what is visible to coaches
  only; a closed poll takes no votes; creating notifies everyone.
- **Done when:** counts are right with several voters; a single-choice poll never holds two votes from one
  account (database test).
- **Needs:** F-12.

### F-19 Lifts

- **Goal:** arrange transport inside the event instead of in a chat thread.
- **Who:** any account in the team offers a car; P and G take or ask for seats for their players.
- **Flow:** Event → Lifts → "Offer a lift" (seats 1–8, optional departure time and note) or "Need a lift"
  (optional note). On an offer: "Join" (choose which child, for guardians) / "Leave". A driver sees requests
  with "I can take you".
- **Data:** `lift_offers`, `lift_passengers`, `lift_requests`.
- **Rules:** one offer per driver and event; a player sits in one car; never more passengers than seats;
  getting a seat removes the player's request; only the driver changes or removes the offer (removing frees
  the passengers); nothing after the event starts.
- **Done when:** the seat count never goes below zero under simultaneous joins (database rule); requests
  disappear when taken.
- **Needs:** F-05.

### F-20 Tasks

- **Goal:** who brings or does what.
- **Who:** C creates and deletes; any account takes a free task and gives back its own.
- **Flow:** Event → Tasks → "Add task" (title) · "I'll do it" · "Give back".
- **Data:** `event_tasks`; `claim_task`.
- **Rules:** title 1–80; one person per task; a coach can free any task.
- **Done when:** two people pressing "I'll do it" at once leave exactly one owner (database rule).
- **Needs:** F-05.

### F-21 Coach notes

- **Goal:** remember what to work on.
- **Who:** C only.
- **Flow:** Event → Notes → "Note for next time" (saved on leaving the field) and, above it, "From last
  time": the note of the team's previous event that has one.
- **Data:** `event_notes`.
- **Rules:** 1–2000 characters; emptying the field deletes the note; never visible to players or guardians.
- **Done when:** a player cannot read notes by any route (database test).
- **Needs:** F-05.

---

## Coach Pro

Built after levels 1 and 2. Enabled per coach by an entitlement (`has_feature('library')`); during the beta it
is granted by hand. Without it the coach sees an explanation and cannot create; content that exists stays
readable.

### F-22 Exercise library

- **Goal:** the coach's own exercises, reused across teams.
- **Who:** the owning coach.
- **Flow:** More → Library → Exercises → "New exercise" → title, category, minutes, description, coaching
  points, video link → Save. Search by title; filter by category; archive instead of delete when used in plans.
- **Data:** `exercises`.
- **Rules:** title 1–80; category from the coach's own list (free text, up to 40); video link must be YouTube
  or Vimeo and opens in the system browser or app — no embedded player in the first version.
- **Done when:** another coach of the same team cannot see the owner's library (database test).

### F-23 Training plans

- **Goal:** a session plan readable at a glance on court.
- **Who:** the owning coach writes; the team reads the plan attached to an event.
- **Flow:** Library → Plans → "New plan" → title → add blocks (from an exercise, or free text) with minutes,
  reorder → "Use in an event" → choose upcoming events. In the Event, the Plan section shows blocks with their
  minute range (0–10′, 10–25′…) and total; the read-only plan screen shows coaching points and video links.
  "Duplicate" copies a plan to adapt it.
- **Data:** `plans`, `plan_blocks`, `event_plans`.
- **Rules:** one plan per event; a plan can be used in many events; editing a plan changes it everywhere it is
  used; detaching does not delete the plan.
- **Done when:** a player sees the plan of their event and nothing else of the library (database test).

### F-24 Assigned exercises

- **Goal:** homework: an exercise for the team or for one player.
- **Who:** the owning coach assigns; the team or the player (and guardians) see it.
- **Flow:** Exercise → "Assign" → team, optionally one player, optional note. Recipients find it under Team →
  Players → their own row ("Exercises for you"), and on Home under Needs you for seven days.
- **Data:** `exercise_assignments`.
- **Rules:** note up to 300; removing the assignment hides the exercise from the recipient.
- **Done when:** an exercise given to one player is invisible to the rest of the team (database test).

---

## Cross-cutting requirements

| Area | Requirement |
|---|---|
| Accessibility | WCAG AA contrast; targets of at least 48 points; visible focus; accessible names on every control; screen-reader alternative to the slide; text scales with the system setting without breaking the layout up to 130% |
| Performance | First screen from a cold start in under 3 seconds on a mid-range Android phone on 4G; lists stay smooth with 200 rows |
| Privacy | Only the data in `DATABASE.md` §8; nothing about minors beyond a name; no analytics or tracking in the first version |
| Reliability | Every write shows success or a clear failure; nothing fails silently; nothing claims to have notified someone unless the server did |
| Security | Row-level security on every table; database tests for every new table and function; no secret in the app |
| Platforms | iOS and Android phones first; web in a centred column; no feature may exist on only one platform, except push notifications (not on web in the first version) |
