import { CheckIcon } from 'phosphor-react-native';
import {StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Divider } from '@/components/ui/Divider';
import { Screen, ScreenHeader } from '@/components/ui/Screen';
import { Section } from '@/components/ui/Section';
import { ErrorView, LoadingView } from '@/components/ui/StateView';
import { Text } from '@/components/ui/Text';
import { repository } from '@/data';
import { useQuery } from '@/hooks/useQuery';
import { useLanguage, languages, type Language } from '@/i18n';
import { color, space, touchTarget } from '@/theme/tokens';
import { Touchable } from '@/components/ui/Touchable';

const languageName: Record<Language, 'more.english' | 'more.spanish'> = { en: 'more.english', es: 'more.spanish' };

/** Settings. For now: the interface language, and a plain note that the data is fictional. */
export default function MoreScreen() {
  const { t, i18n } = useTranslation();
  const me = useQuery('me', () => repository.getCurrentMember());
  const active = useLanguage();

  if (me.error) return <ErrorView onRetry={me.reload} />;
  if (!me.data) return <LoadingView />;

  return (
    <Screen>
      <ScreenHeader overline={me.data.name} title={t('more.title')} />
      <Divider tone="strong" height={2} />
      <Section label={t('more.language')}>
        {languages.map((language) => (
          <Touchable
            key={language}
            accessibilityRole="radio"
            accessibilityState={{ selected: language === active }}
            onPress={() => i18n.changeLanguage(language)}
            style={styles.row}>
            <Text variant="title">{t(languageName[language])}</Text>
            {language === active ? <CheckIcon size={24} weight="bold" color={color.text.default} /> : null}
          </Touchable>
        ))}
      </Section>
      <View style={styles.demo}>
        <Text variant="title">{t('more.demoTitle')}</Text>
        <Text color="muted">{t('more.demoBody')}</Text>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  row: { minHeight: Math.max(56, touchTarget), flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  demo: { margin: space[20], padding: space[20], gap: space[4], backgroundColor: color.bg.subtle },
});
