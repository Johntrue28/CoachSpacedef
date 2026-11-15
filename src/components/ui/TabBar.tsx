import type { BottomTabBarProps } from 'expo-router/js-tabs';
import { CalendarBlankIcon, ChatCircleIcon, HouseIcon, ListIcon, UsersThreeIcon, type Icon } from 'phosphor-react-native';
import {StyleSheet, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { color, space, touchTarget } from '@/theme/tokens';

import { Divider } from './Divider';
import { Text } from './Text';
import { Touchable } from './Touchable';

const tabs: Record<string, { icon: Icon; label: 'home' | 'calendar' | 'team' | 'chat' | 'more'; fill: boolean }> = {
  index: { icon: HouseIcon, label: 'home', fill: true },
  calendar: { icon: CalendarBlankIcon, label: 'calendar', fill: true },
  team: { icon: UsersThreeIcon, label: 'team', fill: true },
  chat: { icon: ChatCircleIcon, label: 'chat', fill: true },
  more: { icon: ListIcon, label: 'more', fill: false },
};

/** Phone navigation. The active tab has a filled icon and a dark label, not only a colour change. */
export function TabBar({ state, emitter, navigateToTab }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  return (
    <View style={styles.root}>
      <Divider />
      <View style={[styles.row, { paddingBottom: Math.max(insets.bottom, space[8]) }]} accessibilityRole="tablist">
        {state.routes.map((route, index) => {
          const tab = tabs[route.name];
          if (!tab) return null;
          const active = state.index === index;
          const TabIcon = tab.icon;
          const tone = active ? color.text.default : color.text.muted;
          return (
            <Touchable
              key={route.key}
              accessibilityRole="tab"
              accessibilityState={{ selected: active }}
              accessibilityLabel={t(`tabs.${tab.label}`)}
              onPress={() => {
                const event = emitter.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
                if (!active && !event.defaultPrevented) navigateToTab(route.key);
              }}
              style={styles.tab}>
              <TabIcon size={24} weight={active && tab.fill ? 'fill' : 'bold'} color={tone} />
              <Text variant="labelSmall" color={active ? 'default' : 'muted'} numberOfLines={1}>
                {t(`tabs.${tab.label}`)}
              </Text>
            </Touchable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { backgroundColor: color.bg.default },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
    maxWidth: 600,
    alignSelf: 'center',
    paddingTop: space[8],
    paddingHorizontal: space[16],
  },
  tab: { flex: 1, minHeight: touchTarget, alignItems: 'center', justifyContent: 'center', gap: space[4] },
});
