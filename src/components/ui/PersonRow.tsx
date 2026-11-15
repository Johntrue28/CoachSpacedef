import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { space } from '@/theme/tokens';

import { Avatar } from './Avatar';
import { Text } from './Text';

/** One person: avatar, name, a detail line and an optional element on the right (an answer). */
export function PersonRow({ name, detail, right }: { name: string; detail?: string; right?: ReactNode }) {
  return (
    <View style={styles.base}>
      <Avatar name={name} />
      <View style={styles.info}>
        <Text variant="title" numberOfLines={2}>
          {name}
        </Text>
        {detail ? (
          <Text color="muted" numberOfLines={2}>
            {detail}
          </Text>
        ) : null}
      </View>
      {right}
    </View>
  );
}

const styles = StyleSheet.create({
  base: { flexDirection: 'row', alignItems: 'center', gap: space[12], paddingVertical: space[12] },
  info: { flex: 1, gap: space[4] },
});
