import type { Answer, AnswerStatus, Member } from '@/data/types';

export type Availability = AnswerStatus | 'none';

export interface AvailabilitySummary {
  in: number;
  out: number;
  none: number;
  total: number;
  answered: number;
}

/** Only players are asked "are you coming?"; coaches are not counted. */
export function playersOf(members: Member[]): Member[] {
  return members.filter((member) => member.role === 'player');
}

export function availabilityOf(member: Member, answers: Answer[]): Availability {
  return answers.find((answer) => answer.memberId === member.id)?.status ?? 'none';
}

export function summarize(members: Member[], answers: Answer[]): AvailabilitySummary {
  const players = playersOf(members);
  const summary = { in: 0, out: 0, none: 0, total: players.length, answered: 0 };
  for (const player of players) {
    summary[availabilityOf(player, answers)] += 1;
  }
  summary.answered = summary.in + summary.out;
  return summary;
}

/** Initials for an avatar: first letter of the first and last word. */
export function initials(name: string): string {
  const words = name.trim().split(/\s+/);
  const first = words[0]?.[0] ?? '';
  const last = words.length > 1 ? (words[words.length - 1][0] ?? '') : '';
  return (first + last).toUpperCase();
}
