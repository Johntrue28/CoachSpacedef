import { PaperPlaneRightIcon } from 'phosphor-react-native';
import { useState } from 'react';
import {KeyboardAvoidingView, Platform, StyleSheet, TextInput, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Divider } from '@/components/ui/Divider';
import { Screen, ScreenHeader } from '@/components/ui/Screen';
import { ErrorView, LoadingView } from '@/components/ui/StateView';
import { Tag } from '@/components/ui/Tag';
import { Text } from '@/components/ui/Text';
import { repository } from '@/data';
import { formatDay, formatTime } from '@/domain/format';
import { useQuery } from '@/hooks/useQuery';
import { useLanguage, dateLocale } from '@/i18n';
import { color, space, touchTarget, type } from '@/theme/tokens';
import { Touchable } from '@/components/ui/Touchable';

async function loadChat() {
  const [team, me, members, messages] = await Promise.all([
    repository.getTeam(),
    repository.getCurrentMember(),
    repository.listMembers(),
    repository.listMessages(),
  ]);
  return { team, me, members, messages };
}

/** Team chat: the latest announcement on top, then the conversation and the composer. */
export default function ChatScreen() {
  const { t } = useTranslation();
  const locale = dateLocale[useLanguage()];
  const query = useQuery('chat', loadChat);
  const [draft, setDraft] = useState('');

  if (query.error) return <ErrorView onRetry={query.reload} />;
  if (!query.data) return <LoadingView />;

  const { team, me, members, messages } = query.data;
  const nameOf = (id: string) => members.find((member) => member.id === id)?.name ?? '';
  const announcement = messages.filter((message) => message.kind === 'announcement').at(-1);
  const conversation = messages.filter((message) => message.kind === 'message');
  const canSend = draft.trim().length > 0;
  const send = () => {
    if (!canSend) return;
    repository.sendMessage(draft.trim());
    setDraft('');
  };

  const composer = (
    <View>
      <Divider />
      <View style={styles.composer}>
        <TextInput
          accessibilityLabel={t('chat.placeholder')}
          placeholder={t('chat.placeholder')}
          placeholderTextColor={color.text.muted}
          value={draft}
          onChangeText={setDraft}
          onSubmitEditing={send}
          returnKeyType="send"
          style={styles.input}
        />
        <Touchable
          accessibilityRole="button"
          accessibilityLabel={t('chat.send')}
          accessibilityState={{ disabled: !canSend }}
          disabled={!canSend}
          onPress={send}
          style={styles.send}>
          <PaperPlaneRightIcon size={24} weight="bold" color={color.text.onAccent} />
        </Touchable>
      </View>
    </View>
  );

  return (
    <KeyboardAvoidingView style={styles.root} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <Screen footer={composer}>
        <ScreenHeader overline={team.name} title={t('chat.title')} />
        {announcement ? (
          <View style={styles.announcement}>
            <Tag variant="accent" label={t('chat.announcement')} />
            <Text variant="bodyStrong" color="inverse">
              {announcement.text}
            </Text>
            <Text variant="labelSmall" color="inverseMuted">
              {`${nameOf(announcement.authorId)} · ${formatDay(announcement.sentAt, locale)} ${formatTime(announcement.sentAt, locale)}`}
            </Text>
          </View>
        ) : null}
        <View style={styles.messages}>
          {conversation.length === 0 ? <Text color="muted">{t('chat.empty')}</Text> : null}
          {conversation.map((message) => {
            const mine = message.authorId === me.id;
            return (
              <View key={message.id} style={[styles.message, mine ? styles.mine : styles.theirs]}>
                {mine ? null : (
                  <Text variant="label" color="muted">
                    {nameOf(message.authorId)}
                  </Text>
                )}
                <Text color={mine ? 'inverse' : 'default'}>{message.text}</Text>
                <Text variant="labelSmall" color={mine ? 'inverseMuted' : 'muted'}>
                  {formatTime(message.sentAt, locale)}
                </Text>
              </View>
            );
          })}
        </View>
      </Screen>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  announcement: { backgroundColor: color.bg.inverse, paddingHorizontal: space[20], paddingVertical: space[16], gap: space[8] },
  messages: { paddingHorizontal: space[20], paddingVertical: space[16], gap: space[12] },
  message: { maxWidth: '80%', padding: space[12], gap: space[4] },
  mine: { alignSelf: 'flex-end', backgroundColor: color.bg.inverse },
  theirs: { alignSelf: 'flex-start', backgroundColor: color.bg.subtle },
  composer: { flexDirection: 'row', alignItems: 'center', gap: space[8], paddingHorizontal: space[20], paddingVertical: space[8] },
  input: {
    ...type.body,
    flex: 1,
    minHeight: touchTarget,
    paddingHorizontal: space[12],
    borderWidth: 1,
    borderColor: color.border.default,
    color: color.text.default,
  },
  send: { width: touchTarget, height: touchTarget, alignItems: 'center', justifyContent: 'center', backgroundColor: color.bg.accent },
});
