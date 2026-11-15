import { useState } from 'react';
import { Platform, Pressable, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';

import { color } from '@/theme/tokens';

interface TouchableProps extends Omit<PressableProps, 'style'> {
  style?: StyleProp<ViewStyle>;
  /** Colour of the focus ring: "inverse" on dark backgrounds. */
  ring?: 'default' | 'inverse';
}

/**
 * The base of every pressable control. It gives all of them the same pressed feedback and a
 * visible focus ring for keyboard users (web, external keyboards).
 */
export function Touchable({ style, ring = 'default', disabled, onFocus, onBlur, ...rest }: TouchableProps) {
  const [focused, setFocused] = useState(false);
  return (
    <Pressable
      {...rest}
      disabled={disabled}
      onFocus={(event) => {
        // On web, show the ring only for keyboard focus, not after a mouse click or a tap.
        const target = event.target as unknown as { matches?: (selector: string) => boolean };
        setFocused(Platform.OS !== 'web' || (target.matches?.(':focus-visible') ?? true));
        onFocus?.(event);
      }}
      onBlur={(event) => {
        setFocused(false);
        onBlur?.(event);
      }}
      style={({ pressed }) => [
        style,
        pressed && { opacity: 0.7 },
        disabled && { opacity: 0.4 },
        focused && {
          outlineWidth: 2,
          outlineStyle: 'solid',
          outlineOffset: 2,
          outlineColor: ring === 'inverse' ? color.text.inverse : color.border.strong,
        },
      ]}
    />
  );
}
