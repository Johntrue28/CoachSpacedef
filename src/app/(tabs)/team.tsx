import { useTranslation } from 'react-i18next';

import { Divider } from '@/components/ui/Divider';
import { PersonRow } from '@/components/ui/PersonRow';
import { Screen, ScreenHeader } from '@/components/ui/Screen';
import { Section } from '@/components/ui/Section';
import { ErrorView, LoadingView } from '@/components/ui/StateView';
import { repository, type Member } from '@/data';
import { playersOf } from '@/domain/availability';
import { useQuery } from '@/hooks/useQuery';

async function loadTeam() {
  const [team, me, members] = await Promise.all([repository.getTeam(), repository.getCurrentMember(), repository.listMembers()]);
  return { team, me, members };
}

/** The people in the team: coaches first, then players. */
export default function TeamScreen() {
  const { t } = useTranslation();
  const query = useQuery('team', loadTeam);

  if (query.error) return <ErrorView onRetry={query.reload} />;
  if (!query.data) return <LoadingView />;

  const { team, me, members } = query.data;
  const players = playersOf(members);
  const coaches = members.filter((member) => member.role !== 'player');
  const playerDetail = (player: Member) =>
    [
      player.number !== undefined ? `#${player.number}` : undefined,
      player.position,
      player.guardianName ? t('team.guardian', { name: player.guardianName }) : undefined,
    ]
      .filter(Boolean)
      .join(' · ');

  return (
    <Screen>
      <ScreenHeader overline={t('team.summary', { players: players.length, coaches: coaches.length })} title={team.name} />
      <Divider tone="strong" height={2} />
      <Section label={t('team.coaches', { count: coaches.length })}>
        {coaches.map((coach) => (
          <PersonRow
            key={coach.id}
            name={coach.name}
            detail={coach.id === me.id ? `${t(`role.${coach.role}`)} · ${t('common.you')}` : t(`role.${coach.role}`)}
          />
        ))}
      </Section>
      <Section label={t('team.players', { count: players.length })}>
        {players.map((player) => (
          <PersonRow key={player.id} name={player.name} detail={playerDetail(player)} />
        ))}
      </Section>
    </Screen>
  );
}
