# CoachSpace — Product

> What CoachSpace is, who it is for and what the first version contains.
> Status: **draft from the discovery interview (November 2026)**. Items marked "open" are not decided.

## 1. Vision

A team app for coaches and amateur clubs that does what TeamPlus does, but is easier to get into and nicer to
use. The owner played basketball and knows the problem first-hand. The project is a learning project with a
commercial ambition: a loyal user base that pays for it.

**Goal for February 2027:** a beta installed on real phones and used by the owner's own club.

## 2. Who it is for

| Who | What they do | Pays? |
|---|---|---|
| **Coach** (also assistant coach) | Creates the team, schedules trainings and matches, sees who is coming, picks the squad, takes attendance, shares documents | Yes (later) |
| **Club coordinator** | Oversees several teams and coaches | Yes (later, level 3) |
| **Treasurer** | Team kitty and fines | Level 3 |
| **Player** (adult or teenager) | Answers "are you coming?", sees the schedule, documents and squad | No |
| **Parent or guardian** | Answers on behalf of a child | No |

- Sports: basketball, football and tennis first. One structure for all sports, with sport-specific words and
  positions as configuration, not as separate products.
- Team types: an independent coach's groups, a club's teams, or an amateur team of friends.
- Markets: Groningen (where the owner lives) and Spain. Interface in English by default, Spanish selectable.

## 3. What the evidence says

Summarised from `RESEARCH.md`. Small sample: four clubs replied to 46 emails.

1. **Getting in is the barrier.** A club that tried a club app went back to WhatsApp: "if you have to log in
   first, you have already lost most people".
2. **WhatsApp is good at chat and bad at memory.** What was missed: a place for documents and links that does
   not scroll away, and a simple way to report an absence.
3. **Too much is a problem.** The old demo was judged "nice, but a lot"; one club found training plans and
   videos "too advanced".
4. Competitors already offer the features. Features alone are not a reason to switch.

**Product principles that follow:**

- **Lowest possible friction to join and answer.** Joining by link; signing in without a password.
- **Few things, easy to find.** Nothing hidden: a complaint about the old demo was that functions were hard to find.
- **The event is the centre.** Who is coming, the squad, lifts and tasks all live in the event.
- **Works next to WhatsApp**, not against it.
- **No ads in the first version.** Ads with minors in the app are a legal and trust risk (open for later).

## 4. Scope of the first version (levels 1 and 2, approved by the owner)

### Level 1 — Core

| Area | Contents |
|---|---|
| Teams | Create a team; invite by link; members list; roles coach, assistant coach, player, guardian |
| Events | Trainings (recurring), matches and tournaments; time, place, notes; change or cancel once for everyone |
| Availability | "Are you coming?" with yes / no and a reason for absence; guardians answer for children |
| Reminders | Push notifications for new events, changes and unanswered invitations |
| Attendance | Register pre-filled from the answers; the coach corrects it |
| Announcements | One-way posts from coaches to the team |
| Documents | Files and links kept per team, always findable |

### Level 2 — Full team

| Area | Contents |
|---|---|
| Squad and line-up | Call-up for a match; line-up |
| Statistics | Attendance per player and per team |
| Polls | Simple votes |
| Lifts | Offer or ask for a lift to an event |
| Tasks | Who brings or does what for an event |

### Later — Level 3 (not in the first version)

Team kitty and fines, treasurer role, club panel across teams, calendar subscription, payments, custom roles.

### Open

- **Chat.** Recommendation: leave it out of the first version (expensive to do well; teams already have
  WhatsApp). The owner has not decided.
- **Exercise library, training plans and videos** from the old demo: not in scope; the only feature a club
  explicitly rejected.

## 5. Roles and permissions (draft, to be detailed before the database is built)

- A person has **one account** and can hold **different roles in different teams** (coach in one, player in another).
- A team can belong to a club or stand alone. A coach can have both kinds.
- A **guardian** is linked to one or more children and acts for them. A child needs no contact details of
  their own.
- Coaches see only their own teams. Club-wide access is a level 3 role.
- Minors: collect the minimum, no health data in free text, EU hosting. Legal review before real users.

## 6. Business model (hypothesis, not decided)

Two plans, as TeamPlus does: a plan per team for coaches and a club plan for several teams. Players and
parents never pay. Reference prices in the market are roughly 50–140 € per team per year, so this is a volume
business. No prices are set and nobody has yet said they would pay.

## 7. What we still need to learn

- Does the owner's club use it for real, week after week?
- Do players and parents answer without being chased?
- Will a coach or a club pay, and for what?
