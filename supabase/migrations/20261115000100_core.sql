-- CoachSpace — migration 1: core (level 1)
-- Identity, clubs, teams, members, guardians, invitations, events, availability, attendance,
-- announcements, chat, documents, notifications.
-- Design and rules: docs/DATABASE.md. Access is enforced here with row-level security (RLS),
-- never only in the interface.

-- ---------------------------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------------------------
create type public.member_role as enum ('coach', 'assistant_coach', 'player');
create type public.event_type as enum ('training', 'match', 'tournament');
create type public.event_status as enum ('scheduled', 'cancelled');
create type public.venue as enum ('home', 'away');
create type public.answer as enum ('in', 'out');
create type public.invite_kind as enum ('member', 'coach');
create type public.join_kind as enum ('player', 'guardian');
create type public.request_status as enum ('pending', 'approved', 'rejected');
create type public.document_kind as enum ('file', 'link');
create type public.chat_mode as enum ('open', 'coaches_only');

-- ---------------------------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------------------------

-- One row per account. The email lives in auth.users and is never exposed to other users.
create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  language text not null default 'en' check (language in ('en', 'es', 'nl')),
  created_at timestamptz not null default now()
);

-- Clubs exist in the model from the start; their panel is level 3.
create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.club_admins (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs (id) on delete set null,
  name text not null check (char_length(name) between 1 and 60),
  sport text not null check (sport in ('basketball', 'football', 'tennis', 'other')),
  -- IANA time zone used to build recurring events and to show times.
  timezone text not null default 'Europe/Amsterdam',
  season_start date not null default (date_trunc('year', now()))::date,
  chat_mode public.chat_mode not null default 'open',
  -- Hours before an event when players who have not answered get one automatic reminder. Null = off.
  reminder_hours smallint default 24 check (reminder_hours between 1 and 72),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  archived_at timestamptz
);
create index teams_club_idx on public.teams (club_id);

-- A person's place in one team. A player may have no account (a child): then user_id is null
-- and one or more guardians act for them.
create table public.members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  role public.member_role not null,
  user_id uuid references auth.users (id) on delete set null,
  display_name text not null check (char_length(display_name) between 1 and 80),
  number smallint check (number between 0 and 999),
  position text check (char_length(position) <= 40),
  created_at timestamptz not null default now(),
  -- Set when the person leaves or is removed. History (attendance) is kept; see DATABASE.md §8.
  left_at timestamptz,
  constraint coaches_have_an_account check (role = 'player' or user_id is not null or left_at is not null)
);
create index members_team_idx on public.members (team_id) where left_at is null;
create index members_user_idx on public.members (user_id) where left_at is null;
-- One active membership per account and team.
create unique index members_one_per_user_and_team on public.members (team_id, user_id)
  where user_id is not null and left_at is null;

-- A guardian (an account) acts for a player.
create table public.guardians (
  member_id uuid not null references public.members (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (member_id, user_id)
);
create index guardians_user_idx on public.guardians (user_id);

create table public.team_invites (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  kind public.invite_kind not null default 'member',
  token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  -- Coach invitations work once.
  used_at timestamptz
);
create index team_invites_team_idx on public.team_invites (team_id);

create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  invite_id uuid references public.team_invites (id) on delete set null,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind public.join_kind not null,
  -- The player's name: the requester's own, or their child's.
  player_name text not null check (char_length(player_name) between 1 and 80),
  status public.request_status not null default 'pending',
  created_at timestamptz not null default now(),
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  member_id uuid references public.members (id) on delete set null
);
create index join_requests_team_idx on public.join_requests (team_id) where status = 'pending';
create unique index join_requests_no_duplicates
  on public.join_requests (team_id, user_id, lower(player_name)) where status = 'pending';

-- A weekly recurrence. Its events are real rows in public.events (see create_event_series).
create table public.event_series (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  type public.event_type not null default 'training',
  title text check (char_length(title) <= 80),
  -- ISO weekdays: 1 = Monday ... 7 = Sunday.
  weekdays smallint[] not null check (
    cardinality(weekdays) between 1 and 7 and weekdays <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]
  ),
  start_time time not null,
  duration_minutes smallint not null check (duration_minutes between 15 and 600),
  place text not null default '' check (char_length(place) <= 120),
  starts_on date not null,
  ends_on date not null,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint series_at_most_a_year check (ends_on >= starts_on and ends_on <= starts_on + 366)
);
create index event_series_team_idx on public.event_series (team_id);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  series_id uuid references public.event_series (id) on delete set null,
  type public.event_type not null,
  -- Opponent or tournament name. A training has none.
  title text check (char_length(title) <= 80),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  place text not null default '' check (char_length(place) <= 120),
  venue public.venue,
  note text check (char_length(note) <= 500),
  status public.event_status not null default 'scheduled',
  cancelled_at timestamptz,
  -- True once this event of a series was changed on its own: "this and following" edits skip it.
  detached boolean not null default false,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint event_ends_after_start check (ends_at > starts_at)
);
create index events_team_time_idx on public.events (team_id, starts_at);
create index events_series_idx on public.events (series_id, starts_at);

-- "Are you coming?" One answer per player and event; the last answer counts.
create table public.availability (
  event_id uuid not null references public.events (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  answer public.answer not null,
  answered_by uuid references auth.users (id) on delete set null,
  answered_at timestamptz not null default now(),
  primary key (event_id, member_id)
);
create index availability_member_idx on public.availability (member_id);

-- The register taken by the coach.
create table public.attendance (
  event_id uuid not null references public.events (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  present boolean not null,
  recorded_by uuid references auth.users (id) on delete set null,
  recorded_at timestamptz not null default now(),
  primary key (event_id, member_id)
);
create index attendance_member_idx on public.attendance (member_id);

create table public.event_reminders (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  kind text not null check (kind in ('auto', 'manual')),
  sent_by uuid references auth.users (id) on delete set null,
  recipients integer not null default 0,
  sent_at timestamptz not null default now()
);
create index event_reminders_event_idx on public.event_reminders (event_id, sent_at desc);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  author_id uuid references auth.users (id) on delete set null,
  title text not null check (char_length(title) between 1 and 80),
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index announcements_team_idx on public.announcements (team_id, created_at desc);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  author_id uuid references auth.users (id) on delete set null,
  -- Emptied when the message is deleted (see delete_message).
  body text not null check (char_length(body) <= 2000),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id) on delete set null
);
create index messages_team_idx on public.messages (team_id, created_at desc);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  kind public.document_kind not null,
  title text not null check (char_length(title) between 1 and 80),
  url text check (url ~ '^https://' and char_length(url) <= 2000),
  -- Path in the private storage bucket "team-documents": <team_id>/<document_id>/<file name>.
  storage_path text,
  mime_type text,
  size_bytes integer check (size_bytes between 1 and 10485760),
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint document_is_a_file_or_a_link check (
    (kind = 'link' and url is not null and storage_path is null)
    or (kind = 'file' and storage_path is not null and url is null)
  )
);
create index documents_team_idx on public.documents (team_id, created_at desc);

-- When each person last looked at the chat and the announcements of a team (for unread marks).
create table public.read_state (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  chat_seen_at timestamptz,
  announcements_seen_at timestamptz,
  primary key (team_id, user_id)
);

create table public.push_tokens (
  token text primary key check (char_length(token) <= 255),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android', 'web')),
  updated_at timestamptz not null default now()
);
create index push_tokens_user_idx on public.push_tokens (user_id);

-- The in-app notification list. Rows are created only by the functions and triggers below;
-- a server function sends each new row as a push notification (see ARCHITECTURE.md).
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  team_id uuid references public.teams (id) on delete cascade,
  event_id uuid references public.events (id) on delete cascade,
  type text not null check (type in (
    'event_created', 'event_changed', 'event_cancelled', 'reminder',
    'join_request', 'join_approved', 'join_rejected', 'announcement',
    'squad_published', 'poll_created'
  )),
  -- Values the app needs to write the text in the reader's language. Never the text itself.
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  pushed_at timestamptz
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- ---------------------------------------------------------------------------------------------
-- Helper functions used by the policies. SECURITY DEFINER so that a policy can look at
-- membership without recursing into the policies of the same tables.
-- ---------------------------------------------------------------------------------------------

create function public.is_team_coach(p_team uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.team_id = p_team and m.user_id = (select auth.uid())
      and m.role in ('coach', 'assistant_coach') and m.left_at is null
  );
$$;

-- Anyone who belongs to the team: a coach, a player with an account, or a guardian of a player.
create function public.is_team_person(p_team uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.team_id = p_team and m.left_at is null and m.user_id = (select auth.uid())
  ) or exists (
    select 1 from public.guardians g
    join public.members m on m.id = g.member_id
    where m.team_id = p_team and m.left_at is null and g.user_id = (select auth.uid())
  );
$$;

-- True when the caller is this player or one of their guardians.
create function public.can_act_for(p_member uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.id = p_member and m.left_at is null and m.user_id = (select auth.uid())
  ) or exists (
    select 1 from public.guardians g
    join public.members m on m.id = g.member_id
    where g.member_id = p_member and m.left_at is null and g.user_id = (select auth.uid())
  );
$$;

create function public.member_team(p_member uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select team_id from public.members where id = p_member;
$$;

create function public.event_team(p_event uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select team_id from public.events where id = p_event;
$$;

-- True when the caller and the other account belong to a common team (to show names).
create function public.shares_team_with(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  with teams_of as (
    select m.team_id, m.user_id from public.members m where m.left_at is null and m.user_id is not null
    union
    select m.team_id, g.user_id from public.guardians g
    join public.members m on m.id = g.member_id where m.left_at is null
  )
  select exists (
    select 1 from teams_of mine join teams_of theirs using (team_id)
    where mine.user_id = (select auth.uid()) and theirs.user_id = p_user
  );
$$;

-- An answer can be given or changed until the event starts, for a player of the event's team.
create function public.can_answer(p_event uuid, p_member uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.events e
    join public.members m on m.team_id = e.team_id
    where e.id = p_event and m.id = p_member
      and m.role = 'player' and m.left_at is null
      and e.status = 'scheduled' and e.starts_at > now()
      and (public.can_act_for(p_member) or public.is_team_coach(e.team_id))
  );
$$;

-- ---------------------------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------------------------

-- Adds one notification per person of the team. Audience: 'all', 'coaches' or 'players'
-- (players with an account and the guardians of players).
create function public.notify_team(
  p_team uuid, p_type text, p_event uuid, p_data jsonb, p_audience text, p_except uuid default null
) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_count integer;
begin
  with audience as (
    select m.user_id from public.members m
    where m.team_id = p_team and m.left_at is null and m.user_id is not null
      and (
        p_audience = 'all'
        or (p_audience = 'coaches' and m.role in ('coach', 'assistant_coach'))
        or (p_audience = 'players' and m.role = 'player')
      )
    union
    select g.user_id from public.guardians g
    join public.members m on m.id = g.member_id
    where m.team_id = p_team and m.left_at is null and m.role = 'player'
      and p_audience in ('all', 'players')
  )
  insert into public.notifications (user_id, team_id, event_id, type, data)
  select a.user_id, p_team, p_event, p_type, coalesce(p_data, '{}'::jsonb)
  from audience a
  where a.user_id is distinct from p_except;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create function public.on_event_inserted() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  -- Events of a series are announced once, by create_event_series.
  if new.series_id is null and new.starts_at > now() then
    perform public.notify_team(new.team_id, 'event_created', new.id, '{}'::jsonb, 'players', (select auth.uid()));
  end if;
  return new;
end;
$$;
create trigger events_after_insert after insert on public.events
  for each row execute function public.on_event_inserted();

create function public.on_event_updated() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.updated_at := now();
  if new.team_id <> old.team_id then
    raise exception 'An event cannot move to another team';
  end if;
  if new.status = 'cancelled' and old.status = 'scheduled' then
    new.cancelled_at := now();
    if old.starts_at > now() then
      perform public.notify_team(new.team_id, 'event_cancelled', new.id, '{}'::jsonb, 'players', (select auth.uid()));
    end if;
  elsif new.status = 'scheduled' and new.starts_at > now()
    and (new.starts_at <> old.starts_at or new.ends_at <> old.ends_at or new.place <> old.place
         or old.status = 'cancelled')
    -- "This and following" edits announce once, from update_following_events.
    and coalesce(current_setting('coachspace.bulk_edit', true), '') <> 'on' then
    perform public.notify_team(
      new.team_id, 'event_changed', new.id,
      jsonb_build_object('time_changed', new.starts_at <> old.starts_at, 'place_changed', new.place <> old.place),
      'players', (select auth.uid())
    );
  end if;
  return new;
end;
$$;
create trigger events_before_update before update on public.events
  for each row execute function public.on_event_updated();

create function public.on_announcement_inserted() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform public.notify_team(
    new.team_id, 'announcement', null, jsonb_build_object('announcement_id', new.id, 'title', new.title),
    'all', new.author_id
  );
  return new;
end;
$$;
create trigger announcements_after_insert after insert on public.announcements
  for each row execute function public.on_announcement_inserted();

-- ---------------------------------------------------------------------------------------------
-- Functions the app calls (RPC)
-- ---------------------------------------------------------------------------------------------

-- Creates a team and makes the caller its coach.
create function public.create_team(p_name text, p_sport text, p_timezone text default 'Europe/Amsterdam')
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
  v_name text;
  v_team uuid;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  select display_name into v_name from public.profiles where user_id = v_user;
  if v_name is null then raise exception 'Set your name first'; end if;
  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_timezone) then
    raise exception 'Unknown time zone';
  end if;
  insert into public.teams (name, sport, timezone, created_by)
  values (p_name, p_sport, p_timezone, v_user) returning id into v_team;
  insert into public.members (team_id, role, user_id, display_name) values (v_team, 'coach', v_user, v_name);
  insert into public.team_invites (team_id, kind, created_by) values (v_team, 'member', v_user);
  return v_team;
end;
$$;

-- What a person sees before joining: only the team's name and sport. Callable without an account.
create function public.get_invite(p_token text)
returns table (team_name text, sport text, kind public.invite_kind)
language sql stable security definer set search_path = '' as $$
  select t.name, t.sport, i.kind
  from public.team_invites i join public.teams t on t.id = i.team_id
  where i.token = p_token and i.revoked_at is null and i.used_at is null
    and (i.expires_at is null or i.expires_at > now()) and t.archived_at is null;
$$;

-- Asks to join as a player or a guardian (a coach approves it), or accepts a coach invitation.
-- Returns the join request id, or null for a coach invitation.
create function public.request_to_join(p_token text, p_kind public.join_kind default null, p_player_name text default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
  v_invite public.team_invites;
  v_name text;
  v_request uuid;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  select display_name into v_name from public.profiles where user_id = v_user;
  if v_name is null then raise exception 'Set your name first'; end if;

  select i.* into v_invite from public.team_invites i join public.teams t on t.id = i.team_id
  where i.token = p_token and i.revoked_at is null and i.used_at is null
    and (i.expires_at is null or i.expires_at > now()) and t.archived_at is null
  for update of i;
  if v_invite.id is null then raise exception 'This invitation is no longer valid'; end if;

  if v_invite.kind = 'coach' then
    if exists (select 1 from public.members where team_id = v_invite.team_id and user_id = v_user and left_at is null) then
      raise exception 'You are already in this team';
    end if;
    insert into public.members (team_id, role, user_id, display_name)
    values (v_invite.team_id, 'assistant_coach', v_user, v_name);
    update public.team_invites set used_at = now() where id = v_invite.id;
    return null;
  end if;

  if p_kind is null then raise exception 'Say whether you are a player or a guardian'; end if;
  if p_kind = 'player' and exists (
    select 1 from public.members where team_id = v_invite.team_id and user_id = v_user and left_at is null
  ) then
    raise exception 'You are already in this team';
  end if;

  insert into public.join_requests (team_id, invite_id, user_id, kind, player_name)
  values (v_invite.team_id, v_invite.id, v_user, p_kind,
          case when p_kind = 'player' then coalesce(nullif(btrim(p_player_name), ''), v_name) else btrim(p_player_name) end)
  returning id into v_request;

  perform public.notify_team(v_invite.team_id, 'join_request', null,
    jsonb_build_object('request_id', v_request), 'coaches');
  return v_request;
end;
$$;

-- A coach approves or rejects a join request. On approval the request is linked to an existing
-- player of the roster (p_existing_member) or a new player is created.
create function public.decide_join_request(p_request uuid, p_approve boolean, p_existing_member uuid default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_request public.join_requests;
  v_member public.members;
begin
  select * into v_request from public.join_requests where id = p_request for update;
  if v_request.id is null or not public.is_team_coach(v_request.team_id) then
    raise exception 'Not allowed';
  end if;
  if v_request.status <> 'pending' then raise exception 'This request was already decided'; end if;

  if not p_approve then
    update public.join_requests set status = 'rejected', decided_by = (select auth.uid()), decided_at = now()
    where id = p_request;
    insert into public.notifications (user_id, team_id, type) values (v_request.user_id, v_request.team_id, 'join_rejected');
    return null;
  end if;

  if p_existing_member is not null then
    select * into v_member from public.members
    where id = p_existing_member and team_id = v_request.team_id and role = 'player' and left_at is null
    for update;
    if v_member.id is null then raise exception 'That player is not in this team'; end if;
    if v_request.kind = 'player' then
      if v_member.user_id is not null then raise exception 'That player already has an account'; end if;
      perform set_config('coachspace.linking', 'on', true);
      update public.members set user_id = v_request.user_id where id = v_member.id;
      perform set_config('coachspace.linking', 'off', true);
    end if;
  else
    insert into public.members (team_id, role, user_id, display_name)
    values (v_request.team_id, 'player',
            case when v_request.kind = 'player' then v_request.user_id end, v_request.player_name)
    returning * into v_member;
  end if;

  if v_request.kind = 'guardian' then
    insert into public.guardians (member_id, user_id) values (v_member.id, v_request.user_id)
    on conflict do nothing;
  end if;

  update public.join_requests
  set status = 'approved', decided_by = (select auth.uid()), decided_at = now(), member_id = v_member.id
  where id = p_request;
  insert into public.notifications (user_id, team_id, type) values (v_request.user_id, v_request.team_id, 'join_approved');
  return v_member.id;
end;
$$;

-- Creates a weekly series and its events (one row per date), in the team's time zone.
create function public.create_event_series(
  p_team uuid, p_type public.event_type, p_title text, p_weekdays smallint[], p_start_time time,
  p_duration_minutes integer, p_place text, p_starts_on date, p_ends_on date
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_series uuid;
  v_zone text;
  v_count integer;
begin
  if not public.is_team_coach(p_team) then raise exception 'Not allowed'; end if;
  select timezone into v_zone from public.teams where id = p_team;

  insert into public.event_series (team_id, type, title, weekdays, start_time, duration_minutes, place, starts_on, ends_on, created_by)
  values (p_team, p_type, nullif(btrim(p_title), ''), p_weekdays, p_start_time, p_duration_minutes,
          coalesce(p_place, ''), p_starts_on, p_ends_on, (select auth.uid()))
  returning id into v_series;

  insert into public.events (team_id, series_id, type, title, starts_at, ends_at, place, created_by)
  select p_team, v_series, p_type, nullif(btrim(p_title), ''),
         (d::date + p_start_time) at time zone v_zone,
         ((d::date + p_start_time) at time zone v_zone) + make_interval(mins => p_duration_minutes),
         coalesce(p_place, ''), (select auth.uid())
  from generate_series(p_starts_on::timestamp, p_ends_on::timestamp, interval '1 day') d
  where extract(isodow from d)::smallint = any (p_weekdays);
  get diagnostics v_count = row_count;
  if v_count = 0 then raise exception 'No dates match these weekdays'; end if;

  perform public.notify_team(p_team, 'event_created', null,
    jsonb_build_object('series_id', v_series, 'count', v_count), 'players', (select auth.uid()));
  return v_series;
end;
$$;

-- "This and following": changes the time, length and place of an event and of the later events of
-- its series that were not changed on their own. Returns how many events changed.
create function public.update_following_events(
  p_event uuid, p_start_time time, p_duration_minutes integer, p_place text
) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_event public.events;
  v_zone text;
  v_count integer;
begin
  select * into v_event from public.events where id = p_event;
  if v_event.id is null or not public.is_team_coach(v_event.team_id) then raise exception 'Not allowed'; end if;
  if v_event.series_id is null then raise exception 'This event does not repeat'; end if;
  if p_duration_minutes not between 15 and 600 then raise exception 'Length must be 15 to 600 minutes'; end if;
  select timezone into v_zone from public.teams where id = v_event.team_id;

  perform set_config('coachspace.bulk_edit', 'on', true);
  update public.events e
  set starts_at = ((e.starts_at at time zone v_zone)::date + p_start_time) at time zone v_zone,
      ends_at = (((e.starts_at at time zone v_zone)::date + p_start_time) at time zone v_zone)
                + make_interval(mins => p_duration_minutes),
      place = coalesce(p_place, e.place)
  where e.series_id = v_event.series_id and e.starts_at >= v_event.starts_at
    and e.status = 'scheduled' and (e.detached = false or e.id = p_event);
  get diagnostics v_count = row_count;
  perform set_config('coachspace.bulk_edit', 'off', true);

  update public.event_series
  set start_time = p_start_time, duration_minutes = p_duration_minutes, place = coalesce(p_place, place)
  where id = v_event.series_id;

  perform public.notify_team(v_event.team_id, 'event_changed', p_event,
    jsonb_build_object('following', true, 'count', v_count), 'players', (select auth.uid()));
  return v_count;
end;
$$;

-- Cancels an event and the later events of its series. Returns how many were cancelled.
create function public.cancel_following_events(p_event uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_event public.events;
  v_count integer;
begin
  select * into v_event from public.events where id = p_event;
  if v_event.id is null or not public.is_team_coach(v_event.team_id) then raise exception 'Not allowed'; end if;
  if v_event.series_id is null then raise exception 'This event does not repeat'; end if;

  -- Later events are removed if nobody is affected yet (no answers); the chosen one is cancelled visibly.
  delete from public.events e
  where e.series_id = v_event.series_id and e.starts_at > v_event.starts_at
    and not exists (select 1 from public.availability a where a.event_id = e.id)
    and not exists (select 1 from public.attendance t where t.event_id = e.id);
  get diagnostics v_count = row_count;

  perform set_config('coachspace.bulk_edit', 'on', true);
  update public.events e set status = 'cancelled', cancelled_at = now()
  where e.series_id = v_event.series_id and e.starts_at > v_event.starts_at and e.status = 'scheduled';
  perform set_config('coachspace.bulk_edit', 'off', true);

  update public.events set status = 'cancelled' where id = p_event and status = 'scheduled';
  update public.event_series set ends_on = greatest(starts_on, (v_event.starts_at)::date) where id = v_event.series_id;
  return v_count + 1;
end;
$$;

-- Saves the register of an event that has started. p_entries: [{"member_id": "...", "present": true}, ...]
create function public.save_register(p_event uuid, p_entries jsonb) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_event public.events;
  v_count integer;
begin
  select * into v_event from public.events where id = p_event;
  if v_event.id is null or not public.is_team_coach(v_event.team_id) then raise exception 'Not allowed'; end if;
  if v_event.status <> 'scheduled' then raise exception 'This event was cancelled'; end if;
  if v_event.starts_at > now() then raise exception 'The register opens when the event starts'; end if;

  insert into public.attendance (event_id, member_id, present, recorded_by)
  select p_event, m.id, (entry ->> 'present')::boolean, (select auth.uid())
  from jsonb_array_elements(p_entries) entry
  join public.members m on m.id = (entry ->> 'member_id')::uuid
  where m.team_id = v_event.team_id and m.role = 'player'
  on conflict (event_id, member_id)
  do update set present = excluded.present, recorded_by = excluded.recorded_by, recorded_at = now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Internal: notifies the people who can answer for the players without an answer.
create function public.send_reminder(p_event uuid, p_kind text, p_sent_by uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_event public.events;
  v_count integer;
begin
  select * into v_event from public.events where id = p_event;
  with missing as (
    select m.id, m.user_id from public.members m
    where m.team_id = v_event.team_id and m.role = 'player' and m.left_at is null
      and not exists (select 1 from public.availability a where a.event_id = p_event and a.member_id = m.id)
  ), people as (
    select user_id from missing where user_id is not null
    union
    select g.user_id from public.guardians g join missing on missing.id = g.member_id
  )
  insert into public.notifications (user_id, team_id, event_id, type)
  select user_id, v_event.team_id, p_event, 'reminder' from people;
  get diagnostics v_count = row_count;
  insert into public.event_reminders (event_id, kind, sent_by, recipients) values (p_event, p_kind, p_sent_by, v_count);
  return v_count;
end;
$$;

-- The coach's "Remind" button. At most one manual reminder per event every hour.
create function public.remind_unanswered(p_event uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_event public.events;
begin
  select * into v_event from public.events where id = p_event;
  if v_event.id is null or not public.is_team_coach(v_event.team_id) then raise exception 'Not allowed'; end if;
  if v_event.status <> 'scheduled' or v_event.starts_at <= now() then
    raise exception 'This event can no longer be answered';
  end if;
  if exists (
    select 1 from public.event_reminders
    where event_id = p_event and kind = 'manual' and sent_at > now() - interval '1 hour'
  ) then
    raise exception 'A reminder was sent less than an hour ago';
  end if;
  return public.send_reminder(p_event, 'manual', (select auth.uid()));
end;
$$;

-- Run by the scheduler every 15 minutes: one automatic reminder per event, at the team's chosen
-- number of hours before it starts.
create function public.queue_due_reminders() returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_event record;
  v_total integer := 0;
begin
  for v_event in
    select e.id from public.events e join public.teams t on t.id = e.team_id
    where e.status = 'scheduled' and t.reminder_hours is not null and t.archived_at is null
      and e.starts_at > now()
      and e.starts_at <= now() + make_interval(hours => t.reminder_hours)
      and not exists (select 1 from public.event_reminders r where r.event_id = e.id and r.kind = 'auto')
  loop
    v_total := v_total + public.send_reminder(v_event.id, 'auto', null);
  end loop;
  return v_total;
end;
$$;

-- Deletes a chat message: its author or a coach. The text is erased; the row stays as a mark.
create function public.delete_message(p_message uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_message public.messages;
begin
  select * into v_message from public.messages where id = p_message;
  if v_message.id is null
     or not (v_message.author_id = (select auth.uid()) or public.is_team_coach(v_message.team_id)) then
    raise exception 'Not allowed';
  end if;
  update public.messages set body = '', deleted_at = now(), deleted_by = (select auth.uid())
  where id = p_message and deleted_at is null;
end;
$$;

-- A player with an account, or a guardian, leaves the team.
create function public.leave_team(p_member uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
  v_member public.members;
begin
  select * into v_member from public.members where id = p_member and left_at is null;
  if v_member.id is null then raise exception 'Not allowed'; end if;
  if v_member.user_id = v_user then
    if v_member.role = 'coach' and not exists (
      select 1 from public.members
      where team_id = v_member.team_id and role = 'coach' and left_at is null and id <> v_member.id
    ) then
      raise exception 'A team needs a coach. Make someone else coach first';
    end if;
    update public.members set left_at = now() where id = p_member;
  elsif exists (select 1 from public.guardians where member_id = p_member and user_id = v_user) then
    delete from public.guardians where member_id = p_member and user_id = v_user;
  else
    raise exception 'Not allowed';
  end if;
end;
$$;

-- Attendance per player since the team's season start: for the coach, every player; for anyone
-- else, only the players they can act for.
create function public.attendance_summary(p_team uuid)
returns table (member_id uuid, sessions integer, present integer)
language sql stable security definer set search_path = '' as $$
  select a.member_id, count(*)::integer, count(*) filter (where a.present)::integer
  from public.attendance a
  join public.events e on e.id = a.event_id
  join public.teams t on t.id = e.team_id
  where e.team_id = p_team and e.status = 'scheduled' and e.starts_at >= t.season_start
    and (public.is_team_coach(p_team) or public.can_act_for(a.member_id))
  group by a.member_id;
$$;

-- ---------------------------------------------------------------------------------------------
-- Guards on direct changes
-- ---------------------------------------------------------------------------------------------

-- Stamps who answered, and keeps the keys of an answer fixed.
create function public.on_availability_written() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.answered_by := (select auth.uid());
  new.answered_at := now();
  return new;
end;
$$;
create trigger availability_before_write before insert or update on public.availability
  for each row execute function public.on_availability_written();

-- A member row cannot change team, and only a full coach changes roles; the last coach stays.
create function public.on_member_updated() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_is_head boolean;
begin
  if new.team_id <> old.team_id then raise exception 'A member cannot move to another team'; end if;
  if (select auth.uid()) is null then return new; end if; -- server-side maintenance
  if new.role <> old.role or new.user_id is distinct from old.user_id then
    select exists (
      select 1 from public.members
      where team_id = old.team_id and user_id = (select auth.uid()) and role = 'coach' and left_at is null
    ) into v_is_head;
    if new.role <> old.role and not v_is_head then raise exception 'Only the coach changes roles'; end if;
    -- Accounts are linked only through decide_join_request; a coach may unlink one.
    if new.user_id is distinct from old.user_id and new.user_id is not null
       and coalesce(current_setting('coachspace.linking', true), '') <> 'on' then
      raise exception 'Accounts are linked through join requests';
    end if;
  end if;
  if old.role = 'coach' and old.left_at is null and (new.role <> 'coach' or new.left_at is not null)
     and not exists (
       select 1 from public.members
       where team_id = old.team_id and role = 'coach' and left_at is null and id <> old.id
     ) then
    raise exception 'A team needs a coach. Make someone else coach first';
  end if;
  return new;
end;
$$;
create trigger members_before_update before update on public.members
  for each row execute function public.on_member_updated();

-- ---------------------------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_admins enable row level security;
alter table public.teams enable row level security;
alter table public.members enable row level security;
alter table public.guardians enable row level security;
alter table public.team_invites enable row level security;
alter table public.join_requests enable row level security;
alter table public.event_series enable row level security;
alter table public.events enable row level security;
alter table public.availability enable row level security;
alter table public.attendance enable row level security;
alter table public.event_reminders enable row level security;
alter table public.announcements enable row level security;
alter table public.messages enable row level security;
alter table public.documents enable row level security;
alter table public.read_state enable row level security;
alter table public.push_tokens enable row level security;
alter table public.notifications enable row level security;

-- profiles: your own, and the names of people you share a team with.
create policy profiles_select on public.profiles for select to authenticated
  using (user_id = (select auth.uid()) or public.shares_team_with(user_id));
create policy profiles_insert on public.profiles for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy profiles_update on public.profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- clubs (level 3): readable by their admins and by the people of their teams. No client writes yet.
create policy clubs_select on public.clubs for select to authenticated
  using (
    exists (select 1 from public.club_admins a where a.club_id = clubs.id and a.user_id = (select auth.uid()))
    or exists (select 1 from public.teams t where t.club_id = clubs.id and public.is_team_person(t.id))
  );
create policy club_admins_select on public.club_admins for select to authenticated
  using (user_id = (select auth.uid()));

-- teams: read by their people; changed by their coaches. Created through create_team.
create policy teams_select on public.teams for select to authenticated
  using (public.is_team_person(id));
create policy teams_update on public.teams for update to authenticated
  using (public.is_team_coach(id)) with check (public.is_team_coach(id));

-- members: the roster is visible to the team; coaches manage it.
create policy members_select on public.members for select to authenticated
  using (public.is_team_person(team_id));
create policy members_insert on public.members for insert to authenticated
  with check (public.is_team_coach(team_id) and role = 'player' and user_id is null);
create policy members_update on public.members for update to authenticated
  using (public.is_team_coach(team_id)) with check (public.is_team_coach(team_id));

-- guardians: seen by the coaches of the team and by the guardian. Created by decide_join_request.
create policy guardians_select on public.guardians for select to authenticated
  using (user_id = (select auth.uid()) or public.is_team_coach(public.member_team(member_id)));
create policy guardians_delete on public.guardians for delete to authenticated
  using (public.is_team_coach(public.member_team(member_id)));

-- invitations: coaches only.
create policy team_invites_select on public.team_invites for select to authenticated
  using (public.is_team_coach(team_id));
create policy team_invites_insert on public.team_invites for insert to authenticated
  with check (public.is_team_coach(team_id) and created_by = (select auth.uid()));
create policy team_invites_update on public.team_invites for update to authenticated
  using (public.is_team_coach(team_id)) with check (public.is_team_coach(team_id));

-- join requests: the requester sees their own; coaches see their team's. Written through functions.
create policy join_requests_select on public.join_requests for select to authenticated
  using (user_id = (select auth.uid()) or public.is_team_coach(team_id));
create policy join_requests_delete on public.join_requests for delete to authenticated
  using (user_id = (select auth.uid()) and status = 'pending');

-- events and series: read by the team; written by coaches.
create policy event_series_select on public.event_series for select to authenticated
  using (public.is_team_person(team_id));
create policy events_select on public.events for select to authenticated
  using (public.is_team_person(team_id));
create policy events_insert on public.events for insert to authenticated
  with check (public.is_team_coach(team_id) and series_id is null);
create policy events_update on public.events for update to authenticated
  using (public.is_team_coach(team_id)) with check (public.is_team_coach(team_id));
create policy events_delete on public.events for delete to authenticated
  using (public.is_team_coach(team_id));

-- availability: the whole team sees who is coming; a player, their guardians or a coach answer.
create policy availability_select on public.availability for select to authenticated
  using (public.is_team_person(public.event_team(event_id)));
create policy availability_insert on public.availability for insert to authenticated
  with check (public.can_answer(event_id, member_id));
create policy availability_update on public.availability for update to authenticated
  using (public.can_answer(event_id, member_id)) with check (public.can_answer(event_id, member_id));

-- attendance: coaches see the register; everyone else sees only their own players' rows.
-- Written through save_register.
create policy attendance_select on public.attendance for select to authenticated
  using (public.is_team_coach(public.event_team(event_id)) or public.can_act_for(member_id));

create policy event_reminders_select on public.event_reminders for select to authenticated
  using (public.is_team_coach(public.event_team(event_id)));

-- announcements: read by the team; written by coaches.
create policy announcements_select on public.announcements for select to authenticated
  using (public.is_team_person(team_id));
create policy announcements_insert on public.announcements for insert to authenticated
  with check (public.is_team_coach(team_id) and author_id = (select auth.uid()));
create policy announcements_delete on public.announcements for delete to authenticated
  using (public.is_team_coach(team_id));

-- chat: read by the team; written by anyone in it while the chat is open, by coaches always.
create policy messages_select on public.messages for select to authenticated
  using (public.is_team_person(team_id));
create policy messages_insert on public.messages for insert to authenticated
  with check (
    author_id = (select auth.uid()) and deleted_at is null and char_length(body) >= 1
    and public.is_team_person(team_id)
    and (public.is_team_coach(team_id)
         or exists (select 1 from public.teams t where t.id = messages.team_id and t.chat_mode = 'open'))
  );

-- documents: read by the team; managed by coaches.
create policy documents_select on public.documents for select to authenticated
  using (public.is_team_person(team_id));
create policy documents_insert on public.documents for insert to authenticated
  with check (public.is_team_coach(team_id) and added_by = (select auth.uid()));
create policy documents_update on public.documents for update to authenticated
  using (public.is_team_coach(team_id)) with check (public.is_team_coach(team_id));
create policy documents_delete on public.documents for delete to authenticated
  using (public.is_team_coach(team_id));

-- personal rows.
create policy read_state_all on public.read_state for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_team_person(team_id));
create policy push_tokens_all on public.push_tokens for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_select on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------------------------
-- Privileges: nothing for visitors without an account except reading an invitation.
-- ---------------------------------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
grant execute on function public.get_invite(text) to anon;
-- Internal functions: not callable from the app.
revoke execute on function public.notify_team(uuid, text, uuid, jsonb, text, uuid) from authenticated;
revoke execute on function public.send_reminder(uuid, text, uuid) from authenticated;
revoke execute on function public.queue_due_reminders() from authenticated;
-- A notification's read mark is the only column a person changes.
revoke update on public.notifications from authenticated;
grant update (read_at) on public.notifications to authenticated;
