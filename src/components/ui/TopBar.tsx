import { CaretLeftIcon } from 'phosphor-react-native';
import {StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { color, space, touchTarget } from '@/theme/tokens';

import { Text } from './Text';
import { Touchable } from './Touchable';

/** Back button and a context label, for screens opened on top of the tabs. */
export function TopBar({ title, onBack, tone = 'light' }: { title: string; onBack: () => void; tone?: 'light' | 'dark' }) {
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  const dark = tone === 'dark';
  return (
    <View style={[styles.base, { paddingTop: insets.top + space[4], backgroundColor: dark ? color.bg.inverse : color.bg.default }]}>
      <Touchable
        accessibilityRole="button"
        accessibilityLabel={t('common.back')}
        onPress={onBack}
        ring={dark ? 'inverse' : 'default'}
        style={styles.back}>
        <CaretLeftIcon size={24} weight="bold" color={dark ? color.text.inverse : color.text.default} />
      </Touchable>
      <Text variant="label" color={dark ? 'inverseMuted' : 'muted'} numberOfLines={1} style={styles.title}>
        {title}
      </Text>
      <View style={styles.back} />
    </View>
  );
}

const styles = StyleSheet.create({
  base: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: space[8], paddingBottom: space[4] },
  back: { width: touchTarget, height: touchTarget, alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1, textAlign: 'center' },
});
