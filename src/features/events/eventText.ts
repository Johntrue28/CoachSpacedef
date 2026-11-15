import { useTranslation } from 'react-i18next';

import type { TeamEvent } from '@/data';
import type { AvailabilitySummary } from '@/domain/availability';
import { countdownTo, formatTime } from '@/domain/format';
import { useLanguage, dateLocale } from '@/i18n';

/** The words used to describe an event in lists and headers, in the current language. */
export function useEventText() {
  const { t } = useTranslation();
  const locale = dateLocale[useLanguage()];

  return {
    locale,
    /** "Training" for a training; the opponent or tournament name otherwise. */
    title: (event: TeamEvent) => event.title ?? t(`eventType.${event.type}`),
    /** The tag shown before the title, for matches and tournaments. */
    tag: (event: TeamEvent) => (event.type === 'training' ? undefined : t(`eventType.${event.type}`)),
    meta: (event: TeamEvent, summary: AvailabilitySummary) =>
      [
        formatTime(event.startsAt, locale),
        event.venue ? t(`event.${event.venue}`) : event.place,
        t('event.answered', { answered: summary.answered, total: summary.total }),
      ].join(' · '),
    countdown: (event: TeamEvent, now: Date) => {
      const value = countdownTo(event.startsAt, now);
      switch (value.kind) {
        case 'past':
          return t('countdown.past');
        case 'now':
          return t('countdown.now');
        case 'minutes':
          return t('countdown.minutes', { m: value.m });
        case 'hours':
          return t('countdown.hours', { h: value.h, m: value.m });
        case 'days':
          return t('countdown.days', { count: value.count });
      }
    },
  };
}
