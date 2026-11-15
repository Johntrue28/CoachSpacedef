import { CheckIcon, QuestionIcon, XIcon } from 'phosphor-react-native';
import { StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import type { Availability } from '@/domain/availability';
import { color, space } from '@/theme/tokens';

import { Text } from './Text';

/** An availability answer. Always icon + label: colour is never the only signal. */
export function AnswerBadge({ answer }: { answer: Availability }) {
  const { t } = useTranslation();
  return (
    <View style={styles.base}>
      {answer === 'in' && <CheckIcon size={16} weight="bold" color={color.text.default} />}
      {answer === 'out' && <XIcon size={16} weight="bold" color={color.text.accent} />}
      {answer === 'none' && <QuestionIcon size={16} weight="bold" color={color.text.muted} />}
      <Text variant="label">{t(`answer.${answer}`)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: { flexDirection: 'row', alignItems: 'center', gap: space[4] },
});
