import { CaretRightIcon } from 'phosphor-react-native';
import {StyleSheet, View } from 'react-native';

import { color, space } from '@/theme/tokens';

import { Tag } from './Tag';
import { Text } from './Text';
import { Touchable } from './Touchable';

interface EventRowProps {
  weekday: string;
  day: string;
  title: string;
  /** Shown as a tag before the title (match, tournament). */
  tag?: string;
  meta: string;
  onPress: () => void;
}

/** One event in a list. The whole row is the touch target. */
export function EventRow({ weekday, day, title, tag, meta, onPress }: EventRowProps) {
  return (
    <Touchable
      accessibilityRole="button"
      accessibilityLabel={[tag, title, weekday, day, meta].filter(Boolean).join(', ')}
      onPress={onPress}
      style={styles.base}>
      <View style={styles.date}>
        <Text variant="label" color="muted">
          {weekday}
        </Text>
        <Text variant="displayHeading">{day}</Text>
      </View>
      <View style={styles.info}>
        <View style={styles.titleRow}>
          {tag ? <Tag label={tag} /> : null}
          <Text variant="title" numberOfLines={1} style={styles.title}>
            {title}
          </Text>
        </View>
        <Text color="muted" numberOfLines={2}>
          {meta}
        </Text>
      </View>
      <CaretRightIcon size={16} weight="bold" color={color.text.muted} />
    </Touchable>
  );
}

const styles = StyleSheet.create({
  base: { flexDirection: 'row', alignItems: 'center', gap: space[16], paddingVertical: space[16], minHeight: 48 },
  date: { width: 40, alignItems: 'center' },
  info: { flex: 1, gap: space[4] },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: space[8] },
  title: { flexShrink: 1 },
});
