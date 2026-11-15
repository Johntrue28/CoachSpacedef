import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { color, space } from '@/theme/tokens';

import { Text } from './Text';

/**
 * Page frame. On wide screens the content keeps a phone-width column: tablet and desktop
 * layouts are not designed yet (see docs/DESIGN.md).
 */
export function Screen({ children, footer, tone = 'light' }: { children: ReactNode; footer?: ReactNode; tone?: 'light' | 'dark' }) {
  return (
    <View style={[styles.root, { backgroundColor: tone === 'dark' ? color.bg.inverse : color.bg.default }]}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        <View style={styles.column}>{children}</View>
      </ScrollView>
      {footer ? <View style={styles.column}>{footer}</View> : null}
    </View>
  );
}

/** Screen title block of a tab: small context line, big title, optional element on the right. */
export function ScreenHeader({ overline, title, right }: { overline: string; title: string; right?: ReactNode }) {
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.header, { paddingTop: insets.top + space[20] }]}>
      <View style={styles.headerText}>
        <Text variant="label" color="muted" numberOfLines={1}>
          {overline}
        </Text>
        <Text variant="displayTitle" accessibilityRole="header" numberOfLines={2}>
          {title}
        </Text>
      </View>
      {right}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  scroll: { flex: 1 },
  content: { flexGrow: 1 },
  column: { width: '100%', maxWidth: 600, alignSelf: 'center' },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    gap: space[16],
    paddingHorizontal: space[20],
    paddingBottom: space[16],
  },
  headerText: { flex: 1, gap: space[4] },
});
