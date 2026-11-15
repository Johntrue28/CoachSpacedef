import type { Repository } from '../repository';
import type { Answer, Member, Message, TeamEvent } from '../types';

/**
 * Fictional data kept in memory. Nothing is saved or sent anywhere: a reload starts again.
 * All names are invented. Dates are built from "now" so the demo never looks out of date.
 */

function at(daysFromToday: number, hours: number, minutes = 0): string {
  const date = new Date();
  date.setDate(date.getDate() + daysFromToday);
  date.setHours(hours, minutes, 0, 0);
  return date.toISOString();
}

/** The next training is always a few hours away, so the home screen has something to show. */
function soon(hoursFromNow: number, durationMinutes: number): { startsAt: string; endsAt: string } {
  const start = new Date(Date.now() + hoursFromNow * 3_600_000);
  start.setMinutes(0, 0, 0);
  return {
    startsAt: start.toISOString(),
    endsAt: new Date(start.getTime() + durationMinutes * 60_000).toISOString(),
  };
}

const team = { id: 'team-u16', name: 'U16 Boys' };

const members: Member[] = [
  { id: 'm-marta', name: 'Marta Vega', role: 'coach' },
  { id: 'm-tom', name: 'Tom Kramer', role: 'assistantCoach' },
  { id: 'm-noah', name: 'Noah Visser', role: 'player', number: 4, position: 'Guard' },
  { id: 'm-daan', name: 'Daan Bakker', role: 'player', number: 5, position: 'Guard', guardianName: 'Eva Bakker' },
  { id: 'm-lars', name: 'Lars de Boer', role: 'player', number: 7, position: 'Guard' },
  { id: 'm-milan', name: 'Milan Smit', role: 'player', number: 9, position: 'Forward' },
  { id: 'm-finn', name: 'Finn Mulder', role: 'player', number: 10, position: 'Forward' },
  { id: 'm-sem', name: 'Sem Jansen', role: 'player', number: 11, position: 'Forward' },
  { id: 'm-pablo', name: 'Pablo Ruiz', role: 'player', number: 12, position: 'Guard' },
  { id: 'm-jesse', name: 'Jesse Bos', role: 'player', number: 13, position: 'Forward' },
  { id: 'm-hugo', name: 'Hugo Martín', role: 'player', number: 15, position: 'Centre' },
  { id: 'm-thijs', name: 'Thijs Maximiliaan van den Heuvel', role: 'player', number: 21, position: 'Centre' },
  { id: 'm-adam', name: 'Adam Haddou', role: 'player', number: 23, position: 'Guard' },
  { id: 'm-ruben', name: 'Rubén Castillo', role: 'player', number: 30, position: 'Forward' },
  { id: 'm-koen', name: 'Koen Dekker', role: 'player', number: 33, position: 'Centre' },
  { id: 'm-iker', name: 'Iker Soto', role: 'player', number: 41, position: 'Guard' },
];

const events: TeamEvent[] = [
  { id: 'e-1', type: 'training', ...soon(3, 90), place: 'Sporthal Noord, court 2', note: 'Bring both kits. We start on time.' },
  { id: 'e-2', type: 'match', title: 'Harbour U16', startsAt: at(2, 10, 30), endsAt: at(2, 12, 0), place: 'Harbour Arena', venue: 'away' },
  { id: 'e-3', type: 'training', startsAt: at(4, 18), endsAt: at(4, 19, 30), place: 'Sporthal Noord, court 2' },
  { id: 'e-4', type: 'training', startsAt: at(7, 18), endsAt: at(7, 19, 30), place: 'Sporthal Noord, court 2' },
  { id: 'e-5', type: 'match', title: 'Delta Basket U16', startsAt: at(9, 12), endsAt: at(9, 13, 30), place: 'Sporthal Noord', venue: 'home' },
  { id: 'e-6', type: 'tournament', title: 'Winter Cup', startsAt: at(16, 9), endsAt: at(16, 17), place: 'Groningen' },
];

const answers: Answer[] = [
  ...['m-lars', 'm-milan', 'm-finn', 'm-jesse', 'm-thijs', 'm-adam', 'm-ruben', 'm-koen', 'm-iker'].map(
    (memberId): Answer => ({ eventId: 'e-1', memberId, status: 'in' }),
  ),
  { eventId: 'e-1', memberId: 'm-daan', status: 'out', reason: 'school' },
  { eventId: 'e-1', memberId: 'm-pablo', status: 'out', reason: 'away' },
  ...['m-lars', 'm-milan', 'm-finn', 'm-hugo', 'm-koen'].map(
    (memberId): Answer => ({ eventId: 'e-2', memberId, status: 'in' }),
  ),
  { eventId: 'e-2', memberId: 'm-iker', status: 'out', reason: 'other' },
  ...['m-lars', 'm-jesse', 'm-adam', 'm-noah'].map((memberId): Answer => ({ eventId: 'e-3', memberId, status: 'in' })),
];

const messages: Message[] = [
  { id: 'c-0', authorId: 'm-marta', kind: 'announcement', sentAt: at(-1, 20, 10), text: 'Saturday we leave at 09:15 from the club car park.' },
  { id: 'c-1', authorId: 'm-tom', kind: 'message', sentAt: at(0, 9, 2), text: 'I can take four in my car on Saturday.' },
  { id: 'c-2', authorId: 'm-lars', kind: 'message', sentAt: at(0, 9, 5), text: 'Can I go with Tom?' },
  { id: 'c-3', authorId: 'm-marta', kind: 'message', sentAt: at(0, 9, 11), text: 'Yes. Tom takes Lars, Daan, Milan and Finn.' },
  { id: 'c-4', authorId: 'm-hugo', kind: 'message', sentAt: at(0, 9, 20), text: 'Which kit, white or black?' },
];

const reminders = new Map<string, string>();
const listeners = new Set<() => void>();

function changed() {
  listeners.forEach((listener) => listener());
}

export const demoRepository: Repository = {
  async getTeam() {
    return team;
  },
  async getCurrentMember() {
    return members[0];
  },
  async listMembers() {
    return [...members];
  },
  async listUpcomingEvents() {
    const now = Date.now();
    return events
      .filter((event) => new Date(event.endsAt).getTime() > now)
      .sort((a, b) => a.startsAt.localeCompare(b.startsAt));
  },
  async getEvent(id) {
    return events.find((event) => event.id === id) ?? null;
  },
  async listAnswers(eventId) {
    return answers.filter((answer) => answer.eventId === eventId);
  },
  async getLastReminder(eventId) {
    return reminders.get(eventId) ?? null;
  },
  async remindUnanswered(eventId) {
    // Demo only: records the moment. No notification exists yet.
    reminders.set(eventId, new Date().toISOString());
    changed();
  },
  async listMessages() {
    return [...messages];
  },
  async sendMessage(text) {
    messages.push({
      id: `c-${messages.length}`,
      authorId: members[0].id,
      kind: 'message',
      sentAt: new Date().toISOString(),
      text,
    });
    changed();
  },
  subscribe(listener) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};
