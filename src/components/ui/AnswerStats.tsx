import { StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import type { AvailabilitySummary } from '@/domain/availability';
import { color, space, type TextColor } from '@/theme/tokens';

import { Text } from './Text';

function Stat({ value, label, tone }: { value: number; label: string; tone: TextColor }) {
  return (
    <View style={styles.stat} accessible accessibilityLabel={`${value} ${label}`}>
      <Text variant="displayStat" color={tone}>
        {value}
      </Text>
      <Text variant="label" color="inverseMuted" style={styles.statLabel}>
        {label}
      </Text>
    </View>
  );
}

/** The three answer totals and the proportional bar. For dark backgrounds. */
export function AnswerStats({ summary }: { summary: AvailabilitySummary }) {
  const { t } = useTranslation();
  return (
    <View style={styles.base}>
      <View style={styles.stats}>
        <Stat value={summary.in} label={t('answer.in')} tone="inverse" />
        <Stat value={summary.out} label={t('answer.out')} tone="accent" />
        <Stat value={summary.none} label={t('answer.none')} tone="inverseMuted" />
      </View>
      {summary.total > 0 && (
        <View style={styles.bar} accessible={false}>
          {summary.in > 0 && <View style={{ flex: summary.in, backgroundColor: color.answer.in }} />}
          {summary.out > 0 && <View style={{ flex: summary.out, backgroundColor: color.answer.out }} />}
          {summary.none > 0 && <View style={{ flex: summary.none, backgroundColor: color.answer.none }} />}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  base: { gap: space[20] },
  stats: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'flex-end', columnGap: space[24], rowGap: space[8] },
  stat: { flexDirection: 'row', alignItems: 'flex-end', gap: space[8] },
  statLabel: { paddingBottom: space[4] },
  bar: { flexDirection: 'row', height: 8, gap: space[4] },
});
