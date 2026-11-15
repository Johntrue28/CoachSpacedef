import { Children, Fragment, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { space } from '@/theme/tokens';

import { Divider } from './Divider';
import { Text } from './Text';

/** A labelled list: an uppercase label, then the rows separated by dividers. */
export function Section({ label, children }: { label: string; children: ReactNode }) {
  const rows = Children.toArray(children);
  return (
    <View style={styles.base}>
      <Text variant="label" color="muted" accessibilityRole="header">
        {label}
      </Text>
      {rows.map((row, index) => (
        <Fragment key={index}>
          {index > 0 && <Divider />}
          {row}
        </Fragment>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  base: { paddingHorizontal: space[20], paddingTop: space[24], paddingBottom: space[8] },
});
