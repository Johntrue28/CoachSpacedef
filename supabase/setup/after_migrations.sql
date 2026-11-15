-- CoachSpace — run once per Supabase project, after the migrations, from the SQL editor.
-- These use Supabase-only features, so they are not part of the migrations and are not covered by
-- the local tests. See docs/SETUP_SUPABASE.md.

-- 1. Live updates: chat messages and answers.
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.availability;

-- 2. Automatic reminders: check every 15 minutes (needs the pg_cron extension, enabled in
--    Database > Extensions).
select cron.schedule('coachspace-reminders', '*/15 * * * *', $$select public.queue_due_reminders()$$);
