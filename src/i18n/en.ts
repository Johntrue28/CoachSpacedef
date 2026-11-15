/** English is the source language. Every key must also exist in es.ts (checked by TypeScript). */
export const en = {
  tabs: { home: 'Home', calendar: 'Calendar', team: 'Team', chat: 'Chat', more: 'More' },
  role: { coach: 'Coach', assistantCoach: 'Assistant coach', player: 'Player' },
  common: {
    back: 'Back',
    loading: 'Loading',
    errorTitle: 'Something went wrong',
    errorBody: 'We could not load this. Try again.',
    retry: 'Try again',
    you: 'you',
  },
  eventType: { training: 'Training', match: 'Match', tournament: 'Tournament' },
  answer: { in: 'In', out: 'Out', none: 'No reply' },
  reason: { school: 'School or work', away: 'Away', other: 'Other' },
  home: {
    title: 'Today',
    next: 'Next',
    thisWeek: 'Coming up',
    remind_one: 'Remind {{count}} player',
    remind_other: 'Remind {{count}} players',
    reminded: 'Reminder sent',
    allAnswered: 'Everyone has answered',
    emptyTitle: 'No events yet',
    emptyBody: 'Add the first training or match. The team gets it and answers with one move.',
    nothingElse: 'Nothing else planned.',
  },
  countdown: {
    now: 'Now',
    minutes: 'In {{m}} min',
    hours: 'In {{h}} h {{m}} min',
    days_one: 'In {{count}} day',
    days_other: 'In {{count}} days',
    past: 'Started',
  },
  event: {
    answered: '{{answered}} of {{total}} answered',
    home: 'Home',
    away: 'Away',
  },
  calendar: { title: 'Calendar', empty: 'No events planned.' },
  team: {
    title: 'Team',
    summary: '{{players}} players · {{coaches}} coaches',
    coaches: 'Coaches · {{count}}',
    players: 'Players · {{count}}',
    guardian: 'guardian: {{name}}',
  },
  chat: {
    title: 'Chat',
    announcement: 'Announcement',
    placeholder: 'Message the team',
    send: 'Send message',
    empty: 'No messages yet.',
  },
  more: {
    title: 'More',
    you: 'You',
    language: 'Language',
    english: 'English',
    spanish: 'Español',
    demoTitle: 'Demo data',
    demoBody: 'This build uses fictional data on this device. Nothing is saved or sent to anyone.',
  },
} as const;

type Widen<T> = { [K in keyof T]: T[K] extends string ? string : Widen<T[K]> };
export type Translations = Widen<typeof en>;
