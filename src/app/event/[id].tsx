import { useLocalSearchParams, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { MapPinIcon } from 'phosphor-react-native';
import { StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { AnswerBadge } from '@/components/ui/AnswerBadge';
import { AnswerStats } from '@/components/ui/AnswerStats';
import { Button } from '@/components/ui/Button';
import { PersonRow } from '@/components/ui/PersonRow';
import { Screen } from '@/components/ui/Screen';
import { Section } from '@/components/ui/Section';
import { ErrorView, LoadingView } from '@/components/ui/StateView';
import { Tag } from '@/components/ui/Tag';
import { Text } from '@/components/ui/Text';
import { TopBar } from '@/components/ui/TopBar';
import { repository, type Member } from '@/data';
import { availabilityOf, playersOf, summarize, type Availability } from '@/domain/availability';
import { formatDay, formatTime } from '@/domain/format';
import { useEventText } from '@/features/events/eventText';
import { useNow } from '@/hooks/useNow';
import { useQuery } from '@/hooks/useQuery';
import { color, space } from '@/theme/tokens';

async function loadEvent(id: string) {
  const [team, event, members, answers, lastReminder] = await Promise.all([
    repository.getTeam(),
    repository.getEvent(id),
    repository.listMembers(),
    repository.listAnswers(id),
    repository.getLastReminder(id),
  ]);
  return { team, event, members, answers, lastReminder };
}

/** Coach view of one event: who is coming, who is not, who has not answered. */
export default function EventScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { t } = useTranslation();
  const router = useRouter();
  const now = useNow();
  const text = useEventText();
  const query = useQuery(`event:${id}`, () => loadEvent(id));

  const back = () => (router.canGoBack() ? router.back() : router.replace('/'));

  if (query.error) return <ErrorView onRetry={query.reload} />;
  if (!query.data) return <LoadingView />;

  const { team, event, members, answers, lastReminder } = query.data;
  if (!event) return <ErrorView onRetry={back} />;

  const summary = summarize(members, answers);
  const players = playersOf(members);
  const group = (answer: Availability) => players.filter((player) => availabilityOf(player, answers) === answer);
  const detail = (player: Member) => {
    const reason = answers.find((answer) => answer.memberId === player.id)?.reason;
    if (reason) return t(`reason.${reason}`);
    return [player.number !== undefined ? `#${player.number}` : undefined, player.position].filter(Boolean).join(' · ');
  };

  const footer =
    summary.none > 0 && !lastReminder ? (
      <View style={styles.footer}>
        <Button label={t('home.remind', { count: summary.none })} onPress={() => repository.remindUnanswered(event.id)} />
      </View>
    ) : undefined;

  return (
    <Screen footer={footer}>
      <StatusBar style="light" />
      <TopBar tone="dark" title={team.name} onBack={back} />
      <View style={styles.hero}>
        <View style={styles.meta}>
          <Tag variant="accent" label={text.countdown(event, now)} />
          <Text variant="label" color="inverseMuted">
            {t(`eventType.${event.type}`)}
          </Text>
        </View>
        <View style={styles.when}>
          {event.title ? (
            <Text variant="displayHeading" color="inverse" accessibilityRole="header">
              {event.title}
            </Text>
          ) : null}
          <Text variant="displayHeading" color="inverseMuted">
            {formatDay(event.startsAt, text.locale)}
          </Text>
          <Text variant="displayXl" color="inverse" adjustsFontSizeToFit numberOfLines={1}>
            {`${formatTime(event.startsAt, text.locale)}–${formatTime(event.endsAt, text.locale)}`}
          </Text>
          <View style={styles.place}>
            <MapPinIcon size={16} weight="bold" color={color.text.accent} />
            <Text color="inverseMuted" style={styles.shrink}>
              {event.place}
            </Text>
          </View>
          {event.note ? <Text color="inverse">{event.note}</Text> : null}
        </View>
        <AnswerStats summary={summary} />
        {lastReminder ? (
          <Text variant="bodyStrong" color="inverse" accessibilityLiveRegion="polite">
            {`${t('home.reminded')} · ${formatTime(lastReminder, text.locale)}`}
          </Text>
        ) : null}
      </View>
      {(['none', 'out', 'in'] as const).map((answer) => {
        const people = group(answer);
        if (people.length === 0) return null;
        return (
          <Section key={answer} label={`${t(`answer.${answer}`)} · ${people.length}`}>
            {people.map((player) => (
              <PersonRow key={player.id} name={player.name} detail={detail(player)} right={<AnswerBadge answer={answer} />} />
            ))}
          </Section>
        );
      })}
    </Screen>
  );
}

const styles = StyleSheet.create({
  hero: { backgroundColor: color.bg.inverse, paddingHorizontal: space[20], paddingTop: space[8], paddingBottom: space[24], gap: space[16] },
  meta: { flexDirection: 'row', alignItems: 'center', gap: space[8] },
  when: { gap: space[8] },
  place: { flexDirection: 'row', alignItems: 'center', gap: space[8] },
  shrink: { flexShrink: 1 },
  footer: {
    paddingHorizontal: space[20],
    paddingTop: space[12],
    paddingBottom: space[32],
    borderTopWidth: 1,
    borderTopColor: color.border.default,
    backgroundColor: color.bg.default,
  },
});
