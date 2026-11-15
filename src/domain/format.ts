/** Date and time formatting. `locale` is a BCP 47 tag such as "en-GB" or "es-ES". */

export function formatTime(iso: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, { hour: '2-digit', minute: '2-digit', hour12: false }).format(new Date(iso));
}

export function formatDay(iso: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, { weekday: 'short', day: 'numeric', month: 'short' }).format(new Date(iso));
}

export function formatWeekday(iso: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, { weekday: 'short' }).format(new Date(iso)).replace('.', '');
}

export function formatDayNumber(iso: string): string {
  return String(new Date(iso).getDate());
}

export function formatMonth(iso: string, locale: string): string {
  return new Intl.DateTimeFormat(locale, { month: 'long', year: 'numeric' }).format(new Date(iso));
}

export type Countdown =
  | { kind: 'past' }
  | { kind: 'now' }
  | { kind: 'minutes'; m: number }
  | { kind: 'hours'; h: number; m: number }
  | { kind: 'days'; count: number };

export function countdownTo(iso: string, now: Date): Countdown {
  const minutes = Math.round((new Date(iso).getTime() - now.getTime()) / 60_000);
  if (minutes < 0) return { kind: 'past' };
  if (minutes === 0) return { kind: 'now' };
  if (minutes < 60) return { kind: 'minutes', m: minutes };
  if (minutes < 24 * 60) return { kind: 'hours', h: Math.floor(minutes / 60), m: minutes % 60 };
  return { kind: 'days', count: Math.floor(minutes / (24 * 60)) };
}
