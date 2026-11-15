import { Tabs } from 'expo-router/js-tabs';

import { TabBar } from '@/components/ui/TabBar';

export default function TabsLayout() {
  return (
    <Tabs screenOptions={{ headerShown: false }} tabBar={(props) => <TabBar {...props} />}>
      <Tabs.Screen name="index" />
      <Tabs.Screen name="calendar" />
      <Tabs.Screen name="team" />
      <Tabs.Screen name="chat" />
      <Tabs.Screen name="more" />
    </Tabs>
  );
}
