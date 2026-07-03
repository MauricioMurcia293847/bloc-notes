-- Repara las politicas RLS de carpetas para usuarios autenticados.
-- Es seguro re-ejecutarlo: elimina solo las politicas CRUD de folders
-- y las vuelve a crear con auth.uid().

alter table public.folders enable row level security;

drop policy if exists "Users can read own folders" on public.folders;
drop policy if exists "Users can insert own folders" on public.folders;
drop policy if exists "Users can update own folders" on public.folders;
drop policy if exists "Users can delete own folders" on public.folders;

create policy "Users can read own folders"
on public.folders for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can insert own folders"
on public.folders for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own folders"
on public.folders for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own folders"
on public.folders for delete
to authenticated
using (auth.uid() = user_id);

select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'folders'
order by policyname;
