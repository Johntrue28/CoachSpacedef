-- CoachSpace — migration 2: level 2
-- Coach notes, squad (call-up and line-up), polls, lifts and tasks. Design: docs/DATABASE.md.

-- ---------------------------------------------------------------------------------------------
-- Coach notes: one private note per event ("notes for next time"). Coaches only.
-- ---------------------------------------------------------------------------------------------
create table public.event_notes (
  event_id uuid primary key references public.events (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  updated_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------------------------
-- Squad: who is called up for a match or tournament, and who starts.
-- ---------------------------------------------------------------------------------------------
create table public.event_squads (
  event_id uuid primary key references public.events (id) on delete cascade,
  -- Players see the squad only once it is published.
  published_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);

create table public.squad_members (
  event_id uuid not null references public.event_squads (event_id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  starter boolean not null default false,
  sort smallint not null default 0,
  primary key (event_id, member_id)
);

create function public.on_squad_updated() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.updated_at := now();
  new.updated_by := (select auth.uid());
  if new.published_at is not null and old.published_at is null then
    perform public.notify_team(public.event_team(new.event_id), 'squad_published', new.event_id,
      '{}'::jsonb, 'players', (select auth.uid()));
  end if;
  return new;
end;
$$;
create trigger event_squads_before_update before update on public.event_squads
  for each row execute function public.on_squad_updated();

create function public.on_squad_member_written() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.members m
    where m.id = new.member_id and m.role = 'player' and m.team_id = public.event_team(new.event_id)
  ) then
    raise exception 'Only players of this team can be in the squad';
  end if;
  return new;
end;
$$;
create trigger squad_members_before_write before insert or update on public.squad_members
  for each row execute function public.on_squad_member_written();

-- ---------------------------------------------------------------------------------------------
-- Polls
-- ---------------------------------------------------------------------------------------------
create table public.polls (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  question text not null check (char_length(question) between 1 and 200),
  multiple boolean not null default false,
  closes_at timestamptz,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index polls_team_idx on public.polls (team_id, created_at desc);

create table public.poll_options (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls (id) on delete cascade,
  label text not null check (char_length(label) between 1 and 80),
  sort smallint not null default 0
);
create index poll_options_poll_idx on public.poll_options (poll_id, sort);

-- One vote per account and option. Written through vote_in_poll.
create table public.poll_votes (
  poll_id uuid not null references public.polls (id) on delete cascade,
  option_id uuid not null references public.poll_options (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (option_id, user_id)
);
create index poll_votes_poll_idx on public.poll_votes (poll_id, user_id);

create function public.poll_team(p_poll uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select team_id from public.polls where id = p_poll;
$$;

-- Creates a poll with its options in one step. p_options: array of labels (2 to 10).
create function public.create_poll(p_team uuid, p_question text, p_options text[], p_multiple boolean default false, p_closes_at timestamptz default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_poll uuid;
begin
  if not public.is_team_coach(p_team) then raise exception 'Not allowed'; end if;
  if cardinality(p_options) not between 2 and 10 then raise exception 'A poll has 2 to 10 options'; end if;
  insert into public.polls (team_id, question, multiple, closes_at, created_by)
  values (p_team, btrim(p_question), p_multiple, p_closes_at, (select auth.uid())) returning id into v_poll;
  insert into public.poll_options (poll_id, label, sort)
  select v_poll, btrim(label), ordinality from unnest(p_options) with ordinality as o(label, ordinality);
  perform public.notify_team(p_team, 'poll_created', null, jsonb_build_object('poll_id', v_poll), 'all', (select auth.uid()));
  return v_poll;
end;
$$;

-- Replaces the caller's vote in a poll with the given options (empty array = withdraw the vote).
create function public.vote_in_poll(p_poll uuid, p_options uuid[]) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_poll public.polls;
  v_user uuid := (select auth.uid());
begin
  select * into v_poll from public.polls where id = p_poll;
  if v_poll.id is null or not public.is_team_person(v_poll.team_id) then raise exception 'Not allowed'; end if;
  if v_poll.closes_at is not null and v_poll.closes_at <= now() then raise exception 'This poll is closed'; end if;
  if not v_poll.multiple and cardinality(p_options) > 1 then raise exception 'Choose one option'; end if;
  if exists (
    select 1 from unnest(p_options) o(id)
    where not exists (select 1 from public.poll_options po where po.id = o.id and po.poll_id = p_poll)
  ) then
    raise exception 'That option is not in this poll';
  end if;
  delete from public.poll_votes where poll_id = p_poll and user_id = v_user;
  insert into public.poll_votes (poll_id, option_id, user_id)
  select p_poll, o.id, v_user from unnest(p_options) o(id);
end;
$$;

-- Vote counts per option, for anyone in the team. Who voted what is visible to coaches only.
create function public.poll_results(p_poll uuid)
returns table (option_id uuid, votes integer)
language sql stable security definer set search_path = '' as $$
  select po.id, count(v.user_id)::integer
  from public.poll_options po
  left join public.poll_votes v on v.option_id = po.id
  where po.poll_id = p_poll and public.is_team_person(public.poll_team(p_poll))
  group by po.id;
$$;

-- ---------------------------------------------------------------------------------------------
-- Lifts: offer seats, join a car, ask for a lift.
-- ---------------------------------------------------------------------------------------------
create table public.lift_offers (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  driver_id uuid not null references auth.users (id) on delete cascade,
  seats smallint not null check (seats between 1 and 8),
  leaves_at timestamptz,
  note text check (char_length(note) <= 120),
  created_at timestamptz not null default now(),
  -- One offer per driver and event.
  unique (event_id, driver_id)
);

create table public.lift_passengers (
  offer_id uuid not null references public.lift_offers (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (offer_id, member_id),
  -- A player rides in one car per event.
  unique (event_id, member_id)
);

create table public.lift_requests (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  member_id uuid not null references public.members (id) on delete cascade,
  note text check (char_length(note) <= 120),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (event_id, member_id)
);

create function public.offer_driver(p_offer uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select driver_id from public.lift_offers where id = p_offer;
$$;

create function public.on_lift_passenger_inserted() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_offer public.lift_offers;
  v_taken integer;
begin
  select * into v_offer from public.lift_offers where id = new.offer_id for update;
  if v_offer.event_id <> new.event_id then raise exception 'That car is for another event'; end if;
  if not exists (
    select 1 from public.members m
    where m.id = new.member_id and m.role = 'player' and m.left_at is null
      and m.team_id = public.event_team(new.event_id)
  ) then
    raise exception 'Only players of this team ride along';
  end if;
  select count(*) into v_taken from public.lift_passengers where offer_id = new.offer_id;
  if v_taken >= v_offer.seats then raise exception 'This car is full'; end if;
  -- The driver takes someone only if that player asked for a lift.
  if not public.can_act_for(new.member_id) and not exists (
    select 1 from public.lift_requests r where r.event_id = new.event_id and r.member_id = new.member_id
  ) then
    raise exception 'That player has not asked for a lift';
  end if;
  new.added_by := (select auth.uid());
  delete from public.lift_requests where event_id = new.event_id and member_id = new.member_id;
  return new;
end;
$$;
create trigger lift_passengers_before_insert before insert on public.lift_passengers
  for each row execute function public.on_lift_passenger_inserted();

-- Fewer seats than passengers is not allowed.
create function public.on_lift_offer_updated() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.event_id <> old.event_id or new.driver_id <> old.driver_id then
    raise exception 'An offer keeps its event and driver';
  end if;
  if new.seats < (select count(*) from public.lift_passengers where offer_id = new.id) then
    raise exception 'There are more passengers than seats';
  end if;
  return new;
end;
$$;
create trigger lift_offers_before_update before update on public.lift_offers
  for each row execute function public.on_lift_offer_updated();

-- True while lifts can still be arranged: the event is planned and has not started.
create function public.event_is_open(p_event uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.events where id = p_event and status = 'scheduled' and starts_at > now());
$$;

-- ---------------------------------------------------------------------------------------------
-- Tasks: who brings or does what for an event.
-- ---------------------------------------------------------------------------------------------
create table public.event_tasks (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  created_by uuid references auth.users (id) on delete set null,
  claimed_by uuid references auth.users (id) on delete set null,
  claimed_at timestamptz,
  created_at timestamptz not null default now()
);
create index event_tasks_event_idx on public.event_tasks (event_id);

-- Takes a free task, or gives back a task the caller took. A coach can free any task.
create function public.claim_task(p_task uuid, p_claim boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_task public.event_tasks;
  v_team uuid;
  v_user uuid := (select auth.uid());
begin
  select * into v_task from public.event_tasks where id = p_task for update;
  v_team := public.event_team(v_task.event_id);
  if v_task.id is null or not public.is_team_person(v_team) then raise exception 'Not allowed'; end if;
  if p_claim then
    if v_task.claimed_by is not null then raise exception 'Someone already took this'; end if;
    update public.event_tasks set claimed_by = v_user, claimed_at = now() where id = p_task;
  else
    if v_task.claimed_by is distinct from v_user and not public.is_team_coach(v_team) then
      raise exception 'Not allowed';
    end if;
    update public.event_tasks set claimed_by = null, claimed_at = null where id = p_task;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------------------------
alter table public.event_notes enable row level security;
alter table public.event_squads enable row level security;
alter table public.squad_members enable row level security;
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;
alter table public.lift_offers enable row level security;
alter table public.lift_passengers enable row level security;
alter table public.lift_requests enable row level security;
alter table public.event_tasks enable row level security;

create policy event_notes_all on public.event_notes for all to authenticated
  using (public.is_team_coach(public.event_team(event_id)))
  with check (public.is_team_coach(public.event_team(event_id)));

create policy event_squads_select on public.event_squads for select to authenticated
  using (
    public.is_team_coach(public.event_team(event_id))
    or (published_at is not null and public.is_team_person(public.event_team(event_id)))
  );
create policy event_squads_insert on public.event_squads for insert to authenticated
  with check (public.is_team_coach(public.event_team(event_id)));
create policy event_squads_update on public.event_squads for update to authenticated
  using (public.is_team_coach(public.event_team(event_id)))
  with check (public.is_team_coach(public.event_team(event_id)));
create policy event_squads_delete on public.event_squads for delete to authenticated
  using (public.is_team_coach(public.event_team(event_id)));

create policy squad_members_select on public.squad_members for select to authenticated
  using (
    public.is_team_coach(public.event_team(event_id))
    or exists (
      select 1 from public.event_squads s
      where s.event_id = squad_members.event_id and s.published_at is not null
        and public.is_team_person(public.event_team(s.event_id))
    )
  );
create policy squad_members_write on public.squad_members for all to authenticated
  using (public.is_team_coach(public.event_team(event_id)))
  with check (public.is_team_coach(public.event_team(event_id)));

create policy polls_select on public.polls for select to authenticated
  using (public.is_team_person(team_id));
create policy polls_update on public.polls for update to authenticated
  using (public.is_team_coach(team_id)) with check (public.is_team_coach(team_id));
create policy polls_delete on public.polls for delete to authenticated
  using (public.is_team_coach(team_id));
create policy poll_options_select on public.poll_options for select to authenticated
  using (public.is_team_person(public.poll_team(poll_id)));
create policy poll_votes_select on public.poll_votes for select to authenticated
  using (user_id = (select auth.uid()) or public.is_team_coach(public.poll_team(poll_id)));

create policy lift_offers_select on public.lift_offers for select to authenticated
  using (public.is_team_person(public.event_team(event_id)));
create policy lift_offers_insert on public.lift_offers for insert to authenticated
  with check (
    driver_id = (select auth.uid()) and public.is_team_person(public.event_team(event_id))
    and public.event_is_open(event_id)
  );
create policy lift_offers_update on public.lift_offers for update to authenticated
  using (driver_id = (select auth.uid())) with check (driver_id = (select auth.uid()));
create policy lift_offers_delete on public.lift_offers for delete to authenticated
  using (driver_id = (select auth.uid()));

create policy lift_passengers_select on public.lift_passengers for select to authenticated
  using (public.is_team_person(public.event_team(event_id)));
create policy lift_passengers_insert on public.lift_passengers for insert to authenticated
  with check (
    public.event_is_open(event_id)
    and (public.can_act_for(member_id) or public.offer_driver(offer_id) = (select auth.uid()))
  );
create policy lift_passengers_delete on public.lift_passengers for delete to authenticated
  using (public.can_act_for(member_id) or public.offer_driver(offer_id) = (select auth.uid()));

create policy lift_requests_select on public.lift_requests for select to authenticated
  using (public.is_team_person(public.event_team(event_id)));
create policy lift_requests_insert on public.lift_requests for insert to authenticated
  with check (
    public.can_act_for(member_id) and created_by = (select auth.uid())
    and public.member_team(member_id) = public.event_team(event_id) and public.event_is_open(event_id)
  );
create policy lift_requests_delete on public.lift_requests for delete to authenticated
  using (public.can_act_for(member_id));

create policy event_tasks_select on public.event_tasks for select to authenticated
  using (public.is_team_person(public.event_team(event_id)));
create policy event_tasks_insert on public.event_tasks for insert to authenticated
  with check (
    public.is_team_coach(public.event_team(event_id)) and created_by = (select auth.uid()) and claimed_by is null
  );
create policy event_tasks_update on public.event_tasks for update to authenticated
  using (public.is_team_coach(public.event_team(event_id)))
  with check (public.is_team_coach(public.event_team(event_id)));
create policy event_tasks_delete on public.event_tasks for delete to authenticated
  using (public.is_team_coach(public.event_team(event_id)));

revoke all on all tables in schema public from anon;
revoke execute on all functions in schema public from public, anon;
grant execute on function public.get_invite(text) to anon;
grant execute on function
  public.poll_team(uuid), public.create_poll(uuid, text, text[], boolean, timestamptz),
  public.vote_in_poll(uuid, uuid[]), public.poll_results(uuid), public.offer_driver(uuid),
  public.event_is_open(uuid), public.claim_task(uuid, boolean)
  to authenticated, service_role;
