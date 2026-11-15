import { Text as NativeText, type TextProps as NativeTextProps } from 'react-native';

import { color, type, type TextColor, type TypeVariant } from '@/theme/tokens';

export interface TextProps extends NativeTextProps {
  variant?: TypeVariant;
  color?: TextColor;
}

/** The only way to put text on screen: every text uses a type style and a colour from the tokens. */
export function Text({ variant = 'body', color: tone = 'default', style, ...rest }: TextProps) {
  return <NativeText {...rest} style={[type[variant], { color: color.text[tone] }, style]} />;
}
