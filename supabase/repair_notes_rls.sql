-- Repara las politicas RLS de notas para usuarios autenticados.
-- Es seguro re-ejecutarlo: elimina solo las politicas CRUD de notes/note_items
-- y las vuelve a crear con auth.uid().

alter table public.notes enable row level security;
alter table public.note_items enable row level security;

drop policy if exists "Users can read own notes" on public.notes;
drop policy if exists "Users can insert own notes" on public.notes;
drop policy if exists "Users can update own notes" on public.notes;
drop policy if exists "Users can delete own notes" on public.notes;

create policy "Users can read own notes"
on public.notes for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can insert own notes"
on public.notes for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own notes"
on public.notes for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own notes"
on public.notes for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read own note items" on public.note_items;
drop policy if exists "Users can insert own note items" on public.note_items;
drop policy if exists "Users can update own note items" on public.note_items;
drop policy if exists "Users can delete own note items" on public.note_items;

create policy "Users can read own note items"
on public.note_items for select
to authenticated
using (
  exists (
    select 1
    from public.notes
    where notes.id = note_items.note_id
      and notes.user_id = auth.uid()
  )
);

create policy "Users can insert own note items"
on public.note_items for insert
to authenticated
with check (
  exists (
    select 1
    from public.notes
    where notes.id = note_items.note_id
      and notes.user_id = auth.uid()
  )
);

create policy "Users can update own note items"
on public.note_items for update
to authenticated
using (
  exists (
    select 1
    from public.notes
    where notes.id = note_items.note_id
      and notes.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.notes
    where notes.id = note_items.note_id
      and notes.user_id = auth.uid()
  )
);

create policy "Users can delete own note items"
on public.note_items for delete
to authenticated
using (
  exists (
    select 1
    from public.notes
    where notes.id = note_items.note_id
      and notes.user_id = auth.uid()
  )
);

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
  and tablename in ('notes', 'note_items')
order by tablename, policyname;
