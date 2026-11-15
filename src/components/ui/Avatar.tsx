import { StyleSheet, View } from 'react-native';

import { initials } from '@/domain/availability';
import { color } from '@/theme/tokens';

import { Text } from './Text';

/** Square avatar with initials only: no photos of minors. */
export function Avatar({ name, tone = 'light' }: { name: string; tone?: 'dark' | 'light' }) {
  return (
    <View accessible={false} style={[styles.base, tone === 'dark' ? styles.dark : styles.light]}>
      <Text variant="bodyStrong" color={tone === 'dark' ? 'inverse' : 'default'}>
        {initials(name)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  dark: { backgroundColor: color.bg.inverse },
  light: { backgroundColor: color.bg.subtle },
});
