import { repository, type Answer, type Member, type Team, type TeamEvent } from '@/data';
import { summarize, type AvailabilitySummary } from '@/domain/availability';

export interface ScheduledEvent {
  event: TeamEvent;
  summary: AvailabilitySummary;
}

export interface Schedule {
  team: Team;
  me: Member;
  members: Member[];
  upcoming: ScheduledEvent[];
}

/** The team, the signed-in member and the upcoming events with their answer totals. */
export async function loadSchedule(): Promise<Schedule> {
  const [team, me, members, events] = await Promise.all([
    repository.getTeam(),
    repository.getCurrentMember(),
    repository.listMembers(),
    repository.listUpcomingEvents(),
  ]);
  const answers: Answer[][] = await Promise.all(events.map((event) => repository.listAnswers(event.id)));
  return {
    team,
    me,
    members,
    upcoming: events.map((event, index) => ({ event, summary: summarize(members, answers[index]) })),
  };
}
