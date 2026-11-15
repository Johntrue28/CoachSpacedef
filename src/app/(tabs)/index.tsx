import { useRouter } from 'expo-router';
import { MapPinIcon } from 'phosphor-react-native';
import {StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { AnswerStats } from '@/components/ui/AnswerStats';
import { Avatar } from '@/components/ui/Avatar';
import { Button } from '@/components/ui/Button';
import { EventRow } from '@/components/ui/EventRow';
import { Screen, ScreenHeader } from '@/components/ui/Screen';
import { Section } from '@/components/ui/Section';
import { ErrorView, LoadingView } from '@/components/ui/StateView';
import { Tag } from '@/components/ui/Tag';
import { Text } from '@/components/ui/Text';
import { repository } from '@/data';
import { formatDay, formatDayNumber, formatTime, formatWeekday } from '@/domain/format';
import { useEventText } from '@/features/events/eventText';
import { loadSchedule } from '@/features/events/loadSchedule';
import { useNow } from '@/hooks/useNow';
import { useQuery } from '@/hooks/useQuery';
import { color, space } from '@/theme/tokens';
import { Touchable } from '@/components/ui/Touchable';

/** Coach home: the next event, who is coming, and the one action that matters (remind). */
export default function HomeScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const now = useNow();
  const text = useEventText();
  const schedule = useQuery('schedule', loadSchedule);
  const nextId = schedule.data?.upcoming[0]?.event.id;
  const reminder = useQuery(`reminder:${nextId}`, () =>
    nextId ? repository.getLastReminder(nextId) : Promise.resolve(null),
  );

  if (schedule.error) return <ErrorView onRetry={schedule.reload} />;
  if (!schedule.data) return <LoadingView />;

  const { team, me, upcoming } = schedule.data;
  const [next, ...rest] = upcoming;
  const header = (
    <ScreenHeader overline={`${team.name} · ${t(`role.${me.role}`)}`} title={t('home.title')} right={<Avatar name={me.name} tone="dark" />} />
  );

  if (!next) {
    return (
      <Screen>
        {header}
        <View style={styles.hero}>
          <Text variant="displayXl" color="inverse">
            {t('home.emptyTitle')}
          </Text>
          <Text color="inverseMuted">{t('home.emptyBody')}</Text>
        </View>
      </Screen>
    );
  }

  const open = (id: string) => router.push({ pathname: '/event/[id]', params: { id } });

  return (
    <Screen>
      {header}
      <View style={styles.hero}>
        <View style={styles.meta}>
          <Text variant="label" color="inverseMuted" style={styles.metaText} numberOfLines={1}>
            {`${t('home.next')} · ${text.title(next.event)}`}
          </Text>
          <Tag variant="accent" label={text.countdown(next.event, now)} />
        </View>
        <Touchable
          accessibilityRole="button"
          accessibilityLabel={`${text.title(next.event)}, ${formatDay(next.event.startsAt, text.locale)}, ${formatTime(next.event.startsAt, text.locale)}, ${next.event.place}`}
          onPress={() => open(next.event.id)}
          ring="inverse"
          style={styles.when}>
          <Text variant="displayHero" color="inverse" adjustsFontSizeToFit numberOfLines={1}>
            {formatTime(next.event.startsAt, text.locale)}
          </Text>
          <View style={styles.place}>
            <MapPinIcon size={16} weight="bold" color={color.text.accent} />
            <Text color="inverseMuted" style={styles.metaText}>
              {`${formatDay(next.event.startsAt, text.locale)} · ${next.event.place}`}
            </Text>
          </View>
        </Touchable>
        <AnswerStats summary={next.summary} />
        {next.summary.none === 0 ? (
          <Text variant="bodyStrong" color="inverse">
            {t('home.allAnswered')}
          </Text>
        ) : reminder.data ? (
          <Text variant="bodyStrong" color="inverse" accessibilityLiveRegion="polite">
            {`${t('home.reminded')} · ${formatTime(reminder.data, text.locale)}`}
          </Text>
        ) : (
          <Button
            label={t('home.remind', { count: next.summary.none })}
            onPress={() => repository.remindUnanswered(next.event.id)}
          />
        )}
      </View>
      <Section label={t('home.thisWeek')}>
        {rest.length === 0 ? (
          <Text color="muted" style={styles.empty}>
            {t('home.nothingElse')}
          </Text>
        ) : (
          rest.slice(0, 3).map(({ event, summary }) => (
            <EventRow
              key={event.id}
              weekday={formatWeekday(event.startsAt, text.locale)}
              day={formatDayNumber(event.startsAt)}
              title={text.title(event)}
              tag={text.tag(event)}
              meta={text.meta(event, summary)}
              onPress={() => open(event.id)}
            />
          ))
        )}
      </Section>
    </Screen>
  );
}

const styles = StyleSheet.create({
  hero: { backgroundColor: color.bg.inverse, padding: space[20], gap: space[20] },
  meta: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: space[12] },
  metaText: { flexShrink: 1 },
  when: { gap: space[8] },
  place: { flexDirection: 'row', alignItems: 'center', gap: space[8] },
  empty: { paddingVertical: space[16] },
});
