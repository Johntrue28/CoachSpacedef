-- Access tests: who can see and change what, between coaches of different teams, players,
-- guardians and strangers. Plain SQL so it runs on any PostgreSQL (see run.sh).
-- All people and teams here are invented.

\set ON_ERROR_STOP on
\o /dev/null
create schema test;
grant usage on schema test to anon, authenticated;

create table test.ids (name text primary key, id uuid not null);
grant select, insert, update on test.ids to anon, authenticated;

create function test.id(p_name text) returns uuid language sql stable as $$
  select id from test.ids where name = p_name;
$$;
create function test.remember(p_name text, p_id uuid) returns void language sql as $$
  insert into test.ids values (p_name, p_id) on conflict (name) do update set id = excluded.id;
$$;
-- Act as a signed-in person, as a visitor, or as the database owner again.
create function test.login(p_name text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', test.id(p_name)::text, false);
  execute 'set role authenticated';
end;
$$;
create function test.visitor() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', '', false);
  execute 'set role anon';
end;
$$;
create function test.owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', '', false);
end;
$$;
create function test.ok(p_condition boolean, p_what text) returns void language plpgsql as $$
begin
  if p_condition is not true then raise exception 'FAILED: %', p_what; end if;
end;
$$;
create function test.rows(p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  execute 'select count(*) from (' || p_sql || ') q' into v;
  return v;
end;
$$;
-- The statement must fail (a refused write, a broken rule).
create function test.refused(p_sql text, p_what text) returns void language plpgsql as $$
declare v_rows bigint;
begin
  begin
    execute p_sql;
    get diagnostics v_rows = row_count;
  exception when others then
    -- Accept only a real refusal: missing privilege or RLS (42501), a rule raised by our own
    -- functions (P0001) or a broken constraint (23xxx). A typo in the test must not pass as a refusal.
    if sqlstate in ('42501', 'P0001') or sqlstate like '23%' then return; end if;
    raise exception 'TEST ERROR in "%": % (%)', p_what, sqlerrm, sqlstate;
  end;
  -- An UPDATE or DELETE hidden by RLS changes nothing instead of failing: that also counts.
  if v_rows = 0 and p_sql ~* '^\s*(update|delete)' then return; end if;
  raise exception 'FAILED (was allowed): %', p_what;
end;
$$;
grant execute on all functions in schema test to anon, authenticated;

-- ---------------------------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------------------------
do $$
declare v_name text; v_id uuid;
begin
  foreach v_name in array array['marta', 'tom', 'ruben', 'lars', 'eva', 'stranger'] loop
    insert into auth.users (email) values (v_name || '@example.com') returning id into v_id;
    perform test.remember(v_name, v_id);
    insert into public.profiles (user_id, display_name) values (v_id, initcap(v_name));
  end loop;
end
$$;

-- ---------------------------------------------------------------------------------------------
-- 1. Teams: each coach sees only their own
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
select test.remember('team_a', public.create_team('U16 Boys', 'basketball'));
insert into public.members (team_id, role, display_name, number) values (test.id('team_a'), 'player', 'Daan Bakker', 5);
select test.remember('daan', (select id from public.members where display_name = 'Daan Bakker'));
select test.ok(test.rows('select 1 from public.teams') = 1, 'coach sees own team');

select test.login('ruben');
select test.remember('team_b', public.create_team('Harbour U16', 'basketball'));
select test.ok(test.rows('select 1 from public.teams') = 1, 'other coach sees only their own team');
select test.ok(test.rows('select 1 from public.members') = 1, 'other coach does not see the roster of team A');
select test.refused(
  format('insert into public.members (team_id, role, display_name) values (%L, ''player'', ''Intruder'')', test.id('team_a')),
  'coach B adds a player to team A');
select test.refused(
  format('update public.teams set name = ''Hacked'' where id = %L', test.id('team_a')), 'coach B renames team A');
select test.refused(
  format('insert into public.members (team_id, role, user_id, display_name) values (%L, ''coach'', %L, ''Ruben'')',
         test.id('team_a'), test.id('ruben')),
  'coach B makes himself coach of team A');

select test.login('stranger');
select test.ok(test.rows('select 1 from public.teams') = 0, 'stranger sees no teams');
select test.ok(test.rows('select 1 from public.members') = 0, 'stranger sees no members');

select test.visitor();
select test.refused('select * from public.teams', 'visitor without account reads teams');

-- ---------------------------------------------------------------------------------------------
-- 2. Joining: link, request, approval
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
create temp table t_token as select token from public.team_invites where team_id = test.id('team_a') and kind = 'member';
grant select on t_token to anon, authenticated;

select test.visitor();
select test.ok((select team_name from public.get_invite((select token from t_token))) = 'U16 Boys', 'visitor reads the invitation');
select test.ok(test.rows('select * from public.get_invite(''nope'')') = 0, 'unknown token shows nothing');

select test.login('lars');
select test.remember('req_lars', public.request_to_join((select token from t_token), 'player', null));
select test.ok(test.rows('select 1 from public.events') = 0 and test.rows('select 1 from public.teams') = 0,
  'a pending request gives no access');
select test.refused(format('select public.decide_join_request(%L, true)', test.id('req_lars')), 'requester approves himself');

select test.login('eva');
select test.remember('req_eva', public.request_to_join((select token from t_token), 'guardian', 'Daan Bakker'));

select test.login('ruben');
select test.refused(format('select public.decide_join_request(%L, true)', test.id('req_lars')), 'coach B approves a request of team A');

select test.login('marta');
select test.ok(test.rows('select 1 from public.join_requests where status = ''pending''') = 2, 'coach sees both requests');
select test.remember('lars_member', public.decide_join_request(test.id('req_lars'), true));
select test.ok(public.decide_join_request(test.id('req_eva'), true, test.id('daan')) = test.id('daan'), 'guardian linked to the existing player');
select test.ok(test.rows('select 1 from public.members where role = ''player''') = 2, 'no duplicate player was created');
select test.ok(test.rows('select 1 from public.guardians') = 1, 'coach sees the guardian link');

select test.login('lars');
select test.ok(test.rows('select 1 from public.teams') = 1, 'approved player sees the team');
select test.ok(test.rows('select 1 from public.guardians') = 0, 'a player does not see who the guardians are');
select test.ok(test.rows('select 1 from public.profiles') = 3, 'names of people in the same team are visible (Marta, Eva, self)');
select test.ok(test.rows('select 1 from public.team_invites') = 0, 'a player cannot read the invitation link');
select test.refused(format('update public.members set role = ''coach'' where id = %L', test.id('lars_member')), 'player makes himself coach');

-- ---------------------------------------------------------------------------------------------
-- 3. Events and answers
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
insert into public.events (team_id, type, starts_at, ends_at, place)
values (test.id('team_a'), 'training', now() + interval '2 days', now() + interval '2 days 90 minutes', 'Sporthal Noord');
select test.remember('event', (select id from public.events where team_id = test.id('team_a')));

select test.login('lars');
select test.ok(test.rows('select 1 from public.notifications where type = ''event_created''') = 1, 'player is told about the new event');
insert into public.availability (event_id, member_id, answer) values (test.id('event'), test.id('lars_member'), 'in');
select test.ok((select answered_by from public.availability where member_id = test.id('lars_member')) = test.id('lars'), 'the answer records who gave it');
select test.refused(
  format('insert into public.availability (event_id, member_id, answer) values (%L, %L, ''out'')', test.id('event'), test.id('daan')),
  'player answers for another player');
select test.refused(format('insert into public.events (team_id, type, starts_at, ends_at) values (%L, ''training'', now() + interval ''1 day'', now() + interval ''2 days'')', test.id('team_a')), 'player creates an event');
select test.refused(format('update public.events set place = ''Elsewhere'' where id = %L', test.id('event')), 'player changes an event');

select test.login('eva');
insert into public.availability (event_id, member_id, answer) values (test.id('event'), test.id('daan'), 'out');
update public.availability set answer = 'in' where event_id = test.id('event') and member_id = test.id('daan');
select test.ok((select answer from public.availability where member_id = test.id('daan')) = 'in', 'guardian changes the child''s answer');
select test.refused(
  format('update public.availability set answer = ''out'' where event_id = %L and member_id = %L', test.id('event'), test.id('lars_member')),
  'guardian changes another player''s answer');
select test.ok(test.rows('select 1 from public.availability') = 2, 'the team sees who is coming');

select test.login('ruben');
select test.ok(test.rows('select 1 from public.events') = 0, 'coach B does not see events of team A');
select test.ok(test.rows('select 1 from public.availability') = 0, 'coach B does not see answers of team A');
select test.refused(
  format('insert into public.availability (event_id, member_id, answer) values (%L, %L, ''in'')', test.id('event'), test.id('daan')),
  'coach B answers in team A');

-- An event that already started: answers are closed, the register opens.
select test.owner();
insert into public.events (team_id, type, starts_at, ends_at)
values (test.id('team_a'), 'training', now() - interval '1 hour', now() + interval '30 minutes');
select test.remember('started', (select id from public.events where starts_at < now()));

select test.login('lars');
select test.refused(
  format('insert into public.availability (event_id, member_id, answer) values (%L, %L, ''in'')', test.id('started'), test.id('lars_member')),
  'answering after the start');

select test.login('marta');
select test.refused(format('select public.save_register(%L, ''[]'')', test.id('event')), 'register before the event starts');
select test.ok(public.save_register(test.id('started'), jsonb_build_array(
  jsonb_build_object('member_id', test.id('lars_member'), 'present', true),
  jsonb_build_object('member_id', test.id('daan'), 'present', false))) = 2, 'coach saves the register');
select test.ok(test.rows('select 1 from public.attendance') = 2, 'coach sees the whole register');

select test.login('lars');
select test.ok(test.rows('select 1 from public.attendance') = 1, 'player sees only his own attendance');
select test.ok((select present from public.attendance_summary(test.id('team_a'))) = 1, 'player sees his own total');
select test.login('eva');
select test.ok(test.rows('select 1 from public.attendance') = 1, 'guardian sees only the child''s attendance');
select test.login('ruben');
select test.refused(format('select public.save_register(%L, ''[]'')', test.id('started')), 'coach B takes the register of team A');
select test.ok(test.rows(format('select * from public.attendance_summary(%L)', test.id('team_a'))) = 0, 'coach B gets no statistics of team A');

-- ---------------------------------------------------------------------------------------------
-- 4. Reminders
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
insert into public.events (team_id, type, title, starts_at, ends_at)
values (test.id('team_a'), 'match', 'Harbour U16', now() + interval '5 days', now() + interval '5 days 2 hours');
select test.remember('match', (select id from public.events where type = 'match'));
select test.ok(public.remind_unanswered(test.id('match')) = 2, 'reminder reaches the player and the guardian');
select test.refused(format('select public.remind_unanswered(%L)', test.id('match')), 'second reminder within the hour');
select test.refused('select public.queue_due_reminders()', 'the app runs the scheduler function');
select test.login('lars');
select test.refused(format('select public.remind_unanswered(%L)', test.id('match')), 'player sends a reminder');
select test.ok(test.rows('select 1 from public.notifications where type = ''reminder''') = 1, 'player received the reminder');
update public.notifications set read_at = now() where type = 'reminder';
select test.refused('update public.notifications set type = ''announcement''', 'player rewrites a notification');
select test.owner();
select test.ok(public.queue_due_reminders() = 0, 'answered event inside the window sends no automatic reminder');
update public.teams set reminder_hours = 72 where id = test.id('team_a');
update public.events set starts_at = now() + interval '3 hours', ends_at = now() + interval '5 hours' where id = test.id('match');
select test.ok(public.queue_due_reminders() = 2, 'automatic reminder is sent once the event is inside the window');
select test.ok(public.queue_due_reminders() = 0, 'and only once');

-- ---------------------------------------------------------------------------------------------
-- 5. Chat, announcements, documents
-- ---------------------------------------------------------------------------------------------
select test.login('lars');
insert into public.messages (team_id, author_id, body) values (test.id('team_a'), test.id('lars'), 'Which kit?');
select test.remember('msg', (select id from public.messages));
select test.refused(format('insert into public.messages (team_id, author_id, body) values (%L, %L, ''as coach'')', test.id('team_a'), test.id('marta')), 'writing a message in someone else''s name');
select test.refused(format('insert into public.announcements (team_id, author_id, title, body) values (%L, %L, ''x'', ''y'')', test.id('team_a'), test.id('lars')), 'player posts an announcement');
select test.refused(format('insert into public.documents (team_id, kind, title, url, added_by) values (%L, ''link'', ''x'', ''https://example.com'', %L)', test.id('team_a'), test.id('lars')), 'player adds a document');
select test.refused(format('update public.messages set body = ''edited'' where id = %L', test.id('msg')), 'editing a sent message');

select test.login('ruben');
select test.ok(test.rows('select 1 from public.messages') = 0, 'coach B cannot read the chat of team A');
select test.refused(format('insert into public.messages (team_id, author_id, body) values (%L, %L, ''hi'')', test.id('team_a'), test.id('ruben')), 'coach B writes in the chat of team A');
select test.refused(format('select public.delete_message(%L)', test.id('msg')), 'coach B deletes a message of team A');

select test.login('marta');
insert into public.announcements (team_id, author_id, title, body) values (test.id('team_a'), test.id('marta'), 'Saturday', 'We leave at 09:15.');
insert into public.documents (team_id, kind, title, url, added_by) values (test.id('team_a'), 'link', 'Club rules', 'https://example.com/rules', test.id('marta'));
select public.delete_message(test.id('msg'));
select test.ok((select body = '' and deleted_at is not null from public.messages where id = test.id('msg')), 'coach deletes a message: text erased');
update public.teams set chat_mode = 'coaches_only' where id = test.id('team_a');

select test.login('lars');
select test.refused(format('insert into public.messages (team_id, author_id, body) values (%L, %L, ''hello'')', test.id('team_a'), test.id('lars')), 'writing while the chat is closed to players');
select test.ok(test.rows('select 1 from public.documents') = 1 and test.rows('select 1 from public.announcements') = 1, 'player reads documents and announcements');
select test.ok(test.rows('select 1 from public.notifications where type = ''announcement''') = 1, 'player is told about the announcement');

-- ---------------------------------------------------------------------------------------------
-- 6. Recurring events
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
select test.remember('series', public.create_event_series(
  test.id('team_a'), 'training', null, array[1, 4]::smallint[], '18:00', 90, 'Sporthal Noord',
  date '2027-01-04', date '2027-01-31'));
select test.ok(test.rows(format('select 1 from public.events where series_id = %L', test.id('series'))) = 8, 'four weeks of Mondays and Thursdays');
select test.ok((select bool_and((starts_at at time zone 'Europe/Amsterdam')::time = '18:00') from public.events where series_id = test.id('series')), 'events start at 18:00 local time');
select test.remember('third', (select id from public.events where series_id = test.id('series') order by starts_at offset 2 limit 1));
select test.ok(public.update_following_events(test.id('third'), '19:00', 60, null) = 6, 'this and following: six events move');
select test.ok(test.rows(format('select 1 from public.events where series_id = %L and (starts_at at time zone ''Europe/Amsterdam'')::time = ''18:00''', test.id('series'))) = 2, 'earlier events keep their time');
select test.ok(public.cancel_following_events(test.id('third')) = 6, 'this and following: six events cancelled or removed');
select test.ok(test.rows(format('select 1 from public.events where series_id = %L and status = ''scheduled''', test.id('series'))) = 2, 'two events remain planned');
select test.login('lars');
select test.refused(format('select public.create_event_series(%L, ''training'', null, array[1]::smallint[], ''18:00'', 90, '''', date ''2027-02-01'', date ''2027-02-28'')', test.id('team_a')), 'player creates a series');
select test.ok(test.rows('select 1 from public.notifications where type = ''event_created'' and data ? ''series_id''') = 1, 'a series is announced once, not once per date');

-- ---------------------------------------------------------------------------------------------
-- 7. Coaches and roles
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
insert into public.team_invites (team_id, kind, created_by, expires_at) values (test.id('team_a'), 'coach', test.id('marta'), now() + interval '7 days');
create temp table t_coach_token as select token from public.team_invites where team_id = test.id('team_a') and kind = 'coach';
grant select on t_coach_token to authenticated;
select test.refused(format('select public.leave_team(%L)', (select id from public.members where user_id = test.id('marta'))), 'the only coach leaves the team');

select test.login('tom');
select public.request_to_join((select token from t_coach_token));
select test.ok(public.is_team_coach(test.id('team_a')), 'assistant coach joined with the coach invitation');
select test.refused(format('update public.members set role = ''coach'' where user_id = %L', test.id('tom')), 'assistant promotes himself');
select test.login('stranger');
select test.refused(format('select public.request_to_join(%L)', (select token from t_coach_token)), 'a coach invitation works once');

-- ---------------------------------------------------------------------------------------------
-- 8. Level 2: notes, squad, polls, lifts, tasks
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
insert into public.event_notes (event_id, body) values (test.id('started'), 'Work on press break next time.');
insert into public.event_squads (event_id) values (test.id('match'));
insert into public.squad_members (event_id, member_id, starter) values (test.id('match'), test.id('lars_member'), true);
select test.refused(format('insert into public.squad_members (event_id, member_id) values (%L, %L)', test.id('match'), (select id from public.members where user_id = test.id('marta'))), 'a coach in the squad');
select test.remember('poll', public.create_poll(test.id('team_a'), 'Which kit on Saturday?', array['White', 'Black']));
insert into public.event_tasks (event_id, title, created_by) values (test.id('match'), 'Bring the oranges', test.id('marta'));
select test.remember('task', (select id from public.event_tasks));

select test.login('lars');
select test.ok(test.rows('select 1 from public.event_notes') = 0, 'coach notes are private');
select test.ok(test.rows('select 1 from public.squad_members') = 0, 'an unpublished squad is not visible');
select test.login('marta');
update public.event_squads set published_at = now() where event_id = test.id('match');
select test.login('lars');
select test.ok(test.rows('select 1 from public.squad_members') = 1, 'a published squad is visible');
select test.ok(test.rows('select 1 from public.notifications where type = ''squad_published''') = 1, 'players are told about the squad');
select test.refused(format('insert into public.squad_members (event_id, member_id) values (%L, %L)', test.id('match'), test.id('daan')), 'player edits the squad');

select public.vote_in_poll(test.id('poll'), array[(select id from public.poll_options where label = 'Black')]);
select test.refused(format('select public.vote_in_poll(%L, array(select id from public.poll_options))', test.id('poll')), 'two options in a single-choice poll');
select test.login('eva');
select public.vote_in_poll(test.id('poll'), array[(select id from public.poll_options where label = 'Black')]);
select test.ok((select votes from public.poll_results(test.id('poll')) r join public.poll_options o on o.id = r.option_id where o.label = 'Black') = 2, 'results count both votes');
select test.ok(test.rows('select 1 from public.poll_votes') = 1, 'a voter sees only their own vote');
select test.login('ruben');
select test.refused(format('select public.vote_in_poll(%L, ''{}'')', test.id('poll')), 'coach B votes in a poll of team A');
select test.ok(test.rows(format('select * from public.poll_results(%L)', test.id('poll'))) = 0, 'coach B gets no results');

select test.login('eva');
insert into public.lift_offers (event_id, driver_id, seats, note) values (test.id('match'), test.id('eva'), 1, 'From the school');
select test.remember('offer', (select id from public.lift_offers));
select test.login('lars');
insert into public.lift_requests (event_id, member_id, created_by) values (test.id('match'), test.id('lars_member'), test.id('lars'));
select test.refused(format('insert into public.lift_passengers (offer_id, event_id, member_id) values (%L, %L, %L)', test.id('offer'), test.id('match'), test.id('daan')), 'player puts someone else in a car');
select test.login('eva');
insert into public.lift_passengers (offer_id, event_id, member_id) values (test.id('offer'), test.id('match'), test.id('lars_member'));
select test.ok(test.rows('select 1 from public.lift_requests') = 0, '"I can take you" ends the request');
select test.refused(format('insert into public.lift_passengers (offer_id, event_id, member_id) values (%L, %L, %L)', test.id('offer'), test.id('match'), test.id('daan')), 'more passengers than seats');
select test.login('ruben');
select test.ok(test.rows('select 1 from public.lift_offers') = 0, 'coach B does not see lifts of team A');
select test.refused(format('insert into public.lift_offers (event_id, driver_id, seats) values (%L, %L, 3)', test.id('match'), test.id('ruben')), 'coach B offers a lift in team A');

select test.login('lars');
select public.claim_task(test.id('task'), true);
select test.login('eva');
select test.refused(format('select public.claim_task(%L, true)', test.id('task')), 'taking a task someone already took');
select test.refused(format('select public.claim_task(%L, false)', test.id('task')), 'freeing someone else''s task');
select test.login('marta');
select public.claim_task(test.id('task'), false);
select test.ok((select claimed_by is null from public.event_tasks), 'coach frees a task');

-- ---------------------------------------------------------------------------------------------
-- 9. Library (paid feature)
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
select test.refused(format('insert into public.exercises (owner_id, title) values (%L, ''3 on 2'')', test.id('marta')), 'library without the paid feature');
select test.owner();
insert into public.entitlements (user_id, feature, source) values (test.id('marta'), 'library', 'beta');
select test.login('marta');
insert into public.exercises (owner_id, title, video_url) values (test.id('marta'), '3 on 2 fast break', 'https://www.youtube.com/watch?v=abc123');
insert into public.exercises (owner_id, title) values (test.id('marta'), 'Private drill');
select test.refused(format('insert into public.exercises (owner_id, title, video_url) values (%L, ''x'', ''https://evil.example/video'')', test.id('marta')), 'a video link that is not YouTube or Vimeo');
insert into public.plans (owner_id, title) values (test.id('marta'), 'Transition day');
insert into public.plan_blocks (plan_id, sort, exercise_id, title, minutes)
select p.id, 1, e.id, e.title, 15 from public.plans p, public.exercises e where e.title like '3 on 2%';
insert into public.event_plans (event_id, plan_id, attached_by) select test.id('event'), id, test.id('marta') from public.plans;
insert into public.exercise_assignments (exercise_id, team_id, member_id, assigned_by)
select id, test.id('team_a'), test.id('daan'), test.id('marta') from public.exercises where title = 'Private drill';

select test.login('lars');
select test.ok(test.rows('select 1 from public.plans') = 1 and test.rows('select 1 from public.plan_blocks') = 1, 'player reads the plan of his event');
select test.ok(test.rows('select 1 from public.exercises') = 1, 'player sees the exercise in the plan, not the one given to another player');
select test.refused('update public.plan_blocks set minutes = 99', 'player edits a plan');
select test.login('eva');
select test.ok(test.rows('select 1 from public.exercises') = 2, 'guardian also sees the exercise given to the child');
select test.login('ruben');
select test.ok(test.rows('select 1 from public.exercises') = 0 and test.rows('select 1 from public.plans') = 0, 'coach B sees nothing of coach A''s library');

-- ---------------------------------------------------------------------------------------------
-- 10. Files
-- ---------------------------------------------------------------------------------------------
select test.login('marta');
insert into storage.objects (bucket_id, name) values ('team-documents', test.id('team_a') || '/doc1/rules.pdf');
select test.login('lars');
select test.ok(test.rows('select 1 from storage.objects') = 1, 'player can open a team file');
select test.refused(format('insert into storage.objects (bucket_id, name) values (''team-documents'', %L)', test.id('team_a') || '/doc2/x.pdf'), 'player uploads a file');
select test.login('ruben');
select test.ok(test.rows('select 1 from storage.objects') = 0, 'coach B cannot open files of team A');
select test.refused(format('insert into storage.objects (bucket_id, name) values (''team-documents'', %L)', test.id('team_a') || '/doc3/x.pdf'), 'coach B uploads into team A');
select test.refused('insert into storage.objects (bucket_id, name) values (''team-documents'', ''not-a-team/x.pdf'')', 'upload outside a team folder');

-- ---------------------------------------------------------------------------------------------
-- 11. Leaving
-- ---------------------------------------------------------------------------------------------
select test.login('eva');
select public.leave_team(test.id('daan'));
select test.ok(test.rows('select 1 from public.teams') = 0, 'a guardian who leaves loses access');
select test.owner();
select test.ok(test.rows('select 1 from public.members where display_name = ''Daan Bakker'' and left_at is null') = 1, 'the child stays on the roster');
\o
\echo access tests: ok
