-- CoachSpace — migration 3: exercise library and training plans (a paid feature for coaches)
-- Designed now so the model does not have to be rebuilt; built after the core. Design: docs/DATABASE.md.

-- What an account is entitled to beyond the free product. During the beta, rows are granted by
-- hand (source 'beta'); payments come later and will write rows with source 'purchase'.
create table public.entitlements (
  user_id uuid not null references auth.users (id) on delete cascade,
  feature text not null check (feature in ('library')),
  source text not null check (source in ('beta', 'purchase', 'club')),
  valid_until timestamptz,
  created_at timestamptz not null default now(),
  primary key (user_id, feature)
);

create function public.has_feature(p_feature text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.entitlements e
    where e.user_id = (select auth.uid()) and e.feature = p_feature
      and (e.valid_until is null or e.valid_until > now())
  );
$$;

-- A coach's own exercises, reused across their teams.
create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  category text check (char_length(category) <= 40),
  description text check (char_length(description) <= 2000),
  coaching_points text check (char_length(coaching_points) <= 2000),
  -- Only YouTube or Vimeo links.
  video_url text check (
    video_url ~ '^https://(www\.)?(youtube\.com/watch\?v=|youtu\.be/|vimeo\.com/)[A-Za-z0-9_\-/?=&]+$'
  ),
  duration_minutes smallint check (duration_minutes between 1 and 180),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);
create index exercises_owner_idx on public.exercises (owner_id) where archived_at is null;

-- A training plan: ordered blocks with minutes. Any plan can be reused in several events.
create table public.plans (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index plans_owner_idx on public.plans (owner_id);

create table public.plan_blocks (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans (id) on delete cascade,
  sort smallint not null default 0,
  exercise_id uuid references public.exercises (id) on delete set null,
  title text not null check (char_length(title) between 1 and 80),
  minutes smallint not null check (minutes between 1 and 180),
  notes text check (char_length(notes) <= 1000)
);
create index plan_blocks_plan_idx on public.plan_blocks (plan_id, sort);

-- The plan of an event: one at most. The team reads it; it is changed in the library.
create table public.event_plans (
  event_id uuid primary key references public.events (id) on delete cascade,
  plan_id uuid not null references public.plans (id) on delete cascade,
  attached_by uuid references auth.users (id) on delete set null,
  attached_at timestamptz not null default now()
);
create index event_plans_plan_idx on public.event_plans (plan_id);

-- An exercise given to a whole team (member_id null) or to one player.
create table public.exercise_assignments (
  id uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  team_id uuid not null references public.teams (id) on delete cascade,
  member_id uuid references public.members (id) on delete cascade,
  note text check (char_length(note) <= 300),
  assigned_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index exercise_assignments_team_idx on public.exercise_assignments (team_id);
create index exercise_assignments_exercise_idx on public.exercise_assignments (exercise_id);

create function public.plan_owner(p_plan uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select owner_id from public.plans where id = p_plan;
$$;

create function public.exercise_owner(p_exercise uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select owner_id from public.exercises where id = p_exercise;
$$;

-- A plan is readable by its owner and by the teams whose events use it.
create function public.can_read_plan(p_plan uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.plan_owner(p_plan) = (select auth.uid()) or exists (
    select 1 from public.event_plans ep
    where ep.plan_id = p_plan and public.is_team_person(public.event_team(ep.event_id))
  );
$$;

-- An exercise is readable by its owner, by whoever it was assigned to, and through a readable plan.
create function public.can_read_exercise(p_exercise uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.exercise_owner(p_exercise) = (select auth.uid())
    or exists (
      select 1 from public.exercise_assignments a
      where a.exercise_id = p_exercise
        and (public.is_team_coach(a.team_id)
             or (a.member_id is null and public.is_team_person(a.team_id))
             or (a.member_id is not null and public.can_act_for(a.member_id)))
    )
    or exists (
      select 1 from public.plan_blocks b
      where b.exercise_id = p_exercise and public.can_read_plan(b.plan_id)
    );
$$;

create function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
create trigger exercises_touch before update on public.exercises
  for each row execute function public.touch_updated_at();
create trigger plans_touch before update on public.plans
  for each row execute function public.touch_updated_at();

alter table public.entitlements enable row level security;
alter table public.exercises enable row level security;
alter table public.plans enable row level security;
alter table public.plan_blocks enable row level security;
alter table public.event_plans enable row level security;
alter table public.exercise_assignments enable row level security;

create policy entitlements_select on public.entitlements for select to authenticated
  using (user_id = (select auth.uid()));

-- Creating and changing needs the paid feature; what exists stays readable (and deletable) without it.
create policy exercises_select on public.exercises for select to authenticated
  using (public.can_read_exercise(id));
create policy exercises_insert on public.exercises for insert to authenticated
  with check (owner_id = (select auth.uid()) and public.has_feature('library'));
create policy exercises_update on public.exercises for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and public.has_feature('library'));
create policy exercises_delete on public.exercises for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy plans_select on public.plans for select to authenticated
  using (public.can_read_plan(id));
create policy plans_insert on public.plans for insert to authenticated
  with check (owner_id = (select auth.uid()) and public.has_feature('library'));
create policy plans_update on public.plans for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and public.has_feature('library'));
create policy plans_delete on public.plans for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy plan_blocks_select on public.plan_blocks for select to authenticated
  using (public.can_read_plan(plan_id));
create policy plan_blocks_write on public.plan_blocks for all to authenticated
  using (public.plan_owner(plan_id) = (select auth.uid()))
  with check (
    public.plan_owner(plan_id) = (select auth.uid()) and public.has_feature('library')
    and (exercise_id is null or public.exercise_owner(exercise_id) = (select auth.uid()))
  );

create policy event_plans_select on public.event_plans for select to authenticated
  using (public.is_team_person(public.event_team(event_id)));
create policy event_plans_write on public.event_plans for all to authenticated
  using (public.is_team_coach(public.event_team(event_id)))
  with check (
    public.is_team_coach(public.event_team(event_id)) and public.plan_owner(plan_id) = (select auth.uid())
    and public.has_feature('library')
  );

create policy exercise_assignments_select on public.exercise_assignments for select to authenticated
  using (
    public.is_team_coach(team_id)
    or (member_id is null and public.is_team_person(team_id))
    or (member_id is not null and public.can_act_for(member_id))
  );
create policy exercise_assignments_insert on public.exercise_assignments for insert to authenticated
  with check (
    public.is_team_coach(team_id) and assigned_by = (select auth.uid())
    and public.exercise_owner(exercise_id) = (select auth.uid()) and public.has_feature('library')
    and (member_id is null or public.member_team(member_id) = team_id)
  );
create policy exercise_assignments_delete on public.exercise_assignments for delete to authenticated
  using (public.is_team_coach(team_id));

revoke all on all tables in schema public from anon;
revoke execute on all functions in schema public from public, anon;
grant execute on function public.get_invite(text) to anon;
grant execute on function
  public.has_feature(text), public.plan_owner(uuid), public.exercise_owner(uuid),
  public.can_read_plan(uuid), public.can_read_exercise(uuid)
  to authenticated, service_role;
