import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { color, space } from '@/theme/tokens';

import { Button } from './Button';
import { Text } from './Text';

/** Loading state of a screen. */
export function LoadingView() {
  const { t } = useTranslation();
  return (
    <View style={styles.base} accessibilityRole="progressbar" accessibilityLabel={t('common.loading')}>
      <ActivityIndicator color={color.text.default} />
    </View>
  );
}

/** Error state of a screen, with a way out. */
export function ErrorView({ onRetry }: { onRetry: () => void }) {
  const { t } = useTranslation();
  return (
    <View style={styles.base}>
      <Text variant="displayHeading">{t('common.errorTitle')}</Text>
      <Text color="muted">{t('common.errorBody')}</Text>
      <Button variant="secondary" label={t('common.retry')} onPress={onRetry} />
    </View>
  );
}

const styles = StyleSheet.create({
  base: { flex: 1, justifyContent: 'center', gap: space[12], padding: space[20] },
});
