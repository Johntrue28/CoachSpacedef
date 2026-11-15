/** Data shapes shared by the app. They describe what a screen needs, not how it is stored. */

export type Role = 'coach' | 'assistantCoach' | 'player';
export type EventType = 'training' | 'match' | 'tournament';
export type AnswerStatus = 'in' | 'out';
/** Absence reasons are a fixed list: no free text, so no health details are collected (proposal O-009). */
export type AbsenceReason = 'school' | 'away' | 'other';

export interface Team {
  id: string;
  name: string;
}

export interface Member {
  id: string;
  name: string;
  role: Role;
  number?: number;
  position?: string;
  /** Set when a guardian answers for this player. */
  guardianName?: string;
}

export interface TeamEvent {
  id: string;
  type: EventType;
  /** Opponent or tournament name. Trainings have none. */
  title?: string;
  /** ISO 8601 date-times. */
  startsAt: string;
  endsAt: string;
  place: string;
  venue?: 'home' | 'away';
  note?: string;
}

export interface Answer {
  eventId: string;
  memberId: string;
  status: AnswerStatus;
  reason?: AbsenceReason;
}

export interface Message {
  id: string;
  authorId: string;
  text: string;
  sentAt: string;
  kind: 'message' | 'announcement';
}
