import { View } from 'react-native';

import { color } from '@/theme/tokens';

export function Divider({ tone = 'default', height = 1 }: { tone?: keyof typeof color.border; height?: number }) {
  return <View style={{ height, alignSelf: 'stretch', backgroundColor: color.border[tone] }} />;
}
