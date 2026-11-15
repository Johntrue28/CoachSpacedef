import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Divider } from '@/components/ui/Divider';
import { EventRow } from '@/components/ui/EventRow';
import { Screen, ScreenHeader } from '@/components/ui/Screen';
import { Section } from '@/components/ui/Section';
import { ErrorView, LoadingView } from '@/components/ui/StateView';
import { Text } from '@/components/ui/Text';
import { formatDayNumber, formatMonth, formatWeekday } from '@/domain/format';
import { useEventText } from '@/features/events/eventText';
import { loadSchedule, type ScheduledEvent } from '@/features/events/loadSchedule';
import { useQuery } from '@/hooks/useQuery';
import { space } from '@/theme/tokens';

/** Every upcoming event, grouped by month. */
export default function CalendarScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const text = useEventText();
  const schedule = useQuery('schedule', loadSchedule);

  if (schedule.error) return <ErrorView onRetry={schedule.reload} />;
  if (!schedule.data) return <LoadingView />;

  const months = new Map<string, ScheduledEvent[]>();
  for (const item of schedule.data.upcoming) {
    const month = formatMonth(item.event.startsAt, text.locale);
    months.set(month, [...(months.get(month) ?? []), item]);
  }

  return (
    <Screen>
      <ScreenHeader overline={schedule.data.team.name} title={t('calendar.title')} />
      <Divider tone="strong" height={2} />
      {months.size === 0 ? (
        <Text color="muted" style={{ padding: space[20] }}>
          {t('calendar.empty')}
        </Text>
      ) : (
        [...months].map(([month, items]) => (
          <Section key={month} label={month}>
            {items.map(({ event, summary }) => (
              <EventRow
                key={event.id}
                weekday={formatWeekday(event.startsAt, text.locale)}
                day={formatDayNumber(event.startsAt)}
                title={text.title(event)}
                tag={text.tag(event)}
                meta={text.meta(event, summary)}
                onPress={() => router.push({ pathname: '/event/[id]', params: { id: event.id } })}
              />
            ))}
          </Section>
        ))
      )}
    </Screen>
  );
}
