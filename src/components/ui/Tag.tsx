import { StyleSheet, View } from 'react-native';

import { color, space } from '@/theme/tokens';

import { Text } from './Text';

type Variant = 'solid' | 'accent' | 'outline';

const textColor = { solid: 'inverse', accent: 'onAccent', outline: 'default' } as const;

/** Short uppercase label: event type, countdown, state. */
export function Tag({ label, variant = 'solid' }: { label: string; variant?: Variant }) {
  return (
    <View style={[styles.base, styles[variant]]}>
      <Text variant="label" color={textColor[variant]} numberOfLines={1}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: { alignSelf: 'flex-start', paddingHorizontal: space[8], paddingVertical: space[4], borderWidth: 1, borderColor: 'transparent' },
  solid: { backgroundColor: color.bg.inverse },
  accent: { backgroundColor: color.bg.accent },
  outline: { borderColor: color.border.strong },
});
