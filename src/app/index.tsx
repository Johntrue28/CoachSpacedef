import { StyleSheet, Text, View } from 'react-native';

/**
 * Placeholder screen. It only proves that the project runs on iOS, Android and web.
 * Real screens are built after the design direction is approved (see docs/ROADMAP.md).
 */
export default function Index() {
  return (
    <View style={styles.container}>
      <Text accessibilityRole="header" style={styles.title}>
        CoachSpace
      </Text>
      <Text style={styles.note}>Project foundation. No product screens yet.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
  title: { fontSize: 28, fontWeight: '700' },
  note: { marginTop: 8, fontSize: 16, textAlign: 'center' },
});
