import { ArrowRightIcon } from 'phosphor-react-native';
import {StyleSheet } from 'react-native';

import { color, space } from '@/theme/tokens';

import { Text } from './Text';
import { Touchable } from './Touchable';

type Variant = 'primary' | 'secondary' | 'inverse';

interface ButtonProps {
  label: string;
  onPress: () => void;
  variant?: Variant;
  disabled?: boolean;
}

const textColor = { primary: 'onAccent', secondary: 'default', inverse: 'inverse' } as const;

/** Main action of a screen: 56 high, full width, square corners. One primary button per screen. */
export function Button({ label, onPress, variant = 'primary', disabled = false }: ButtonProps) {
  return (
    <Touchable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={[styles.base, styles[variant]]}>
      <Text variant="displayButton" color={textColor[variant]} numberOfLines={1} style={styles.label}>
        {label}
      </Text>
      <ArrowRightIcon size={24} weight="bold" color={color.text[textColor[variant]]} />
    </Touchable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: space[12],
    paddingHorizontal: space[20],
    paddingVertical: space[16],
    borderWidth: 2,
    borderColor: 'transparent',
  },
  label: { flexShrink: 1 },
  primary: { backgroundColor: color.bg.accent },
  secondary: { borderColor: color.border.strong },
  inverse: { backgroundColor: color.bg.inverseSubtle },
});
