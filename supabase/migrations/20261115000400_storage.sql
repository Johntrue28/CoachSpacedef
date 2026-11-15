-- CoachSpace — migration 4: file storage for team documents
-- A private bucket. Files live at <team_id>/<document_id>/<file name>; the first folder decides access.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'team-documents', 'team-documents', false, 10485760,
  array['application/pdf', 'image/jpeg', 'image/png',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
on conflict (id) do nothing;

-- The team a stored file belongs to, or null if the path does not start with a team id.
create function public.storage_team(p_name text) returns uuid
language plpgsql immutable set search_path = '' as $$
begin
  return split_part(p_name, '/', 1)::uuid;
exception when others then
  return null;
end;
$$;

create policy team_documents_read on storage.objects for select to authenticated
  using (bucket_id = 'team-documents' and public.is_team_person(public.storage_team(name)));
create policy team_documents_add on storage.objects for insert to authenticated
  with check (bucket_id = 'team-documents' and public.is_team_coach(public.storage_team(name)));
create policy team_documents_remove on storage.objects for delete to authenticated
  using (bucket_id = 'team-documents' and public.is_team_coach(public.storage_team(name)));

revoke execute on function public.storage_team(text) from public, anon;
grant execute on function public.storage_team(text) to authenticated, service_role;
