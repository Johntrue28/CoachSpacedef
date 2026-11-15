import type { Answer, Member, Message, Team, TeamEvent } from './types';

/**
 * Everything the screens can ask for or change. Screens depend on this interface only, so the
 * fictional data used today can be replaced by the real backend without touching the screens.
 * Every method is asynchronous because the real backend will be.
 */
export interface Repository {
  getTeam(): Promise<Team>;
  getCurrentMember(): Promise<Member>;
  listMembers(): Promise<Member[]>;
  /** Events that have not ended yet, soonest first. */
  listUpcomingEvents(): Promise<TeamEvent[]>;
  getEvent(id: string): Promise<TeamEvent | null>;
  listAnswers(eventId: string): Promise<Answer[]>;
  /** ISO date-time of the last reminder for the event, or null. */
  getLastReminder(eventId: string): Promise<string | null>;
  remindUnanswered(eventId: string): Promise<void>;
  listMessages(): Promise<Message[]>;
  sendMessage(text: string): Promise<void>;
  /** Calls the listener after any change. Returns a function that stops listening. */
  subscribe(listener: () => void): () => void;
}
