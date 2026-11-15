# CoachSpace — Product

> What CoachSpace is, who it is for, what it contains and the rules it follows.
> Status: **defined** (November 2026, decisions D-001 to D-031 and A-001 to A-015). This document and `DECISIONS.md` are the
> source of truth for scope. Details of each function are in `FEATURE_SPECIFICATIONS.md`.

## 1. Vision

A team app for coaches and amateur clubs that does what TeamPlus does, but is easier to get into and nicer to
use. The founder played basketball and knows the problem first-hand. It is a learning project with a
commercial ambition: a loyal user base that pays for it.

**Goal for February 2027:** a beta installed on real phones and used every week by the founder's own club.

## 2. Who it is for

| Who | What they do | Pays? |
|---|---|---|
| **Coach** | Creates the team, schedules trainings, matches and tournaments, sees who is coming, takes the register, posts announcements, keeps documents | Yes, later (plans in §7) |
| **Assistant coach** | The same as the coach, except changing roles | No |
| **Player, 16 or older** | Answers "are you coming?", sees the schedule, squad, documents, chat | Never |
| **Parent or guardian** | Does all of that on behalf of a child under 16, who has no account | Never |
| **Club administrator** | Oversees several teams (level 3, later) | Yes, later |

- **Sports:** basketball, football and tennis first, plus "other". One structure for all; sport-specific words
  (positions) are configuration.
- **Team types:** a club's team, an independent coach's group, an amateur team of friends. In the product all
  three are a **team**; a team may belong to a club or stand alone.
- **Markets:** the Groningen area and Spain. Interface in English (default), Spanish and Dutch.

## 3. What the evidence says

Summarised from `RESEARCH.md`. Small sample: four clubs replied to 46 emails.

1. **Getting in is the barrier.** "If you have to log in first, you have already lost most people."
2. **WhatsApp is good at chat and bad at memory.** Missed: a place for documents that does not scroll away,
   and a simple way to sign a child off a training.
3. **Too much is a problem.** The old demo was "nice, but a lot"; training plans and videos were "too
   advanced" for one club.
4. Competitors already have the features. Features alone are not a reason to switch.

## 4. Product principles

1. **Lowest possible friction to join and answer.** Join by link; sign in with a code sent by email, no password.
2. **Few things, easy to find.** Five tabs, the same for everyone. Nothing hidden behind gestures only.
3. **The event is the centre.** Who is coming, the squad, lifts, tasks, the plan and the register live in the event.
4. **One primary action per screen**, and each action in one place only.
5. **Works next to WhatsApp**, not against it. The team chat exists, but nothing depends on moving there.
6. **Coach tools stay out of the players' way.** The library, notes and statistics are visible to coaches;
   players see only what concerns them.
7. **Minors first.** Under 16: no account, no private chat, no photos, no rankings. Minimum data.
8. **No ads.** Players and guardians never pay.

## 5. Scope

### Level 1 — Core

| Area | Contents |
|---|---|
| Accounts | Sign in with an email code; name; language |
| Teams | Create a team; invite by link; a coach approves each request; roster; roles; several teams per person |
| Events | Trainings (weekly recurrence), matches, tournaments; time, place, note; change or cancel once for everyone |
| Availability | "Are you coming?": in or out, until the event starts; guardians answer for children; a coach can record an answer |
| Reminders | Push notifications for new events, changes, cancellations; one automatic reminder and a manual "Remind" for those who have not answered |
| Attendance | Register pre-filled from the answers once the event starts; the coach corrects and saves it |
| Announcements | One-way posts from coaches; the latest is pinned on Home |
| Chat | One team chat, text only; coaches can delete messages and close the chat to players |
| Documents | Files and links kept per team |

### Level 2 — Full team

| Area | Contents |
|---|---|
| Statistics | Attendance per player and per team for the season; each player sees only their own |
| Squad and line-up | Call-up for a match or tournament; starters and bench; published when the coach decides |
| Polls | Simple votes, one or several choices |
| Lifts | Offer seats, join a car, ask for a lift, per event |
| Tasks | Who brings or does what for an event |
| Coach notes | A private note per event; "from last time" shows the previous one |

### Coach Pro — paid feature (built after the core)

| Area | Contents |
|---|---|
| Exercise library | A coach's own exercises with description, coaching points and a YouTube or Vimeo link |
| Training plans | Ordered blocks with minutes; attached to events; read-only for the team |
| Assigned exercises | An exercise given to a team or to one player |

### Later — Level 3 and beyond (not in the first version)

Team kitty and fines, treasurer role, club panel across teams, payments and subscriptions in the app, calendar
subscription, custom roles, desktop layout for coaches, accounts for under-16s authorised by a guardian,
private chats, photos in chat, absence reasons.

### Deliberately out

Ads; streaks, badges, points or rankings; a "maybe" answer; a reason for absence; profile photos; private
chats between an adult and a minor; a central "+" button; photographs as decoration.

## 6. Roles and permissions (summary)

The full matrix is in `DATABASE.md` §6; the database enforces it.

| Action | Coach | Assistant | Player 16+ | Guardian |
|---|---|---|---|---|
| See the team, schedule, answers, documents, chat, announcements | Yes | Yes | Yes | Yes |
| Answer "are you coming?" | For any player | For any player | For themselves | For their children |
| Create, change, cancel events; remind; take the register | Yes | Yes | No | No |
| Post announcements; manage documents; delete chat messages | Yes | Yes | No | No |
| Approve join requests; add and remove players | Yes | Yes | No | No |
| Change roles; invite a coach | Yes | No | No | No |
| See the register and statistics of everyone | Yes | Yes | Own only | Own children only |
| See who the guardians are | Yes | Yes | No | Themselves |
| Coach notes; library and plans (own) | Yes | Yes | No | No |

- One account per person; a person can be coach in one team and player or guardian in another.
- A child under 16 is a name on the roster with one or more guardians. The child has no login and no contact
  details. The age rule is a declaration at joining ("I am 16 or older"); no birth date is stored.

## 7. Business model (hypothesis; nothing is charged before the beta ends)

- **Free:** everything in levels 1 and 2, for every team. No ads.
- **Coach Pro:** the exercise library, training plans and assigned exercises. Per coach.
- **Club:** several teams under one club with the club panel (level 3).

During the beta, Coach Pro is switched on by hand for the coaches who test it. No prices are set and nobody has
yet said they would pay. Reference prices in the market are roughly 50–140 € per team per year (`RESEARCH.md`).

## 8. Constraints

- Budget: at most 20 € per month for services during the beta. Store fees (Apple, Google) not yet approved.
- One person reviews; Claude builds. iOS can be tested only when a borrowed iPhone is available.
- No legal entity yet. A privacy notice and the question of who is responsible for the data must be settled
  before real users; see `ROADMAP.md`.

## 9. What we still need to learn

- Does the founder's club use it for real, week after week?
- Do players and parents answer without being chased?
- Will a coach pay for the planning tools, and how much?
