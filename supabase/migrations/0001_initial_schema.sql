create extension if not exists "pgcrypto";

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, name)
);

create type public.note_type as enum ('text', 'checklist');

create table public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  folder_id uuid references public.folders(id) on delete set null,
  title text not null default '',
  body text not null default '',
  note_type public.note_type not null default 'text',
  is_pinned boolean not null default false,
  reminder_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.note_items (
  id uuid primary key default gen_random_uuid(),
  note_id uuid not null references public.notes(id) on delete cascade,
  content text not null,
  is_done boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index folders_user_id_idx on public.folders(user_id);
create index notes_user_id_idx on public.notes(user_id);
create index notes_folder_id_idx on public.notes(folder_id);
create index notes_deleted_at_idx on public.notes(deleted_at);
create index notes_updated_at_idx on public.notes(updated_at desc);
create index note_items_note_id_idx on public.note_items(note_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger folders_set_updated_at
before update on public.folders
for each row execute function public.set_updated_at();

create trigger notes_set_updated_at
before update on public.notes
for each row execute function public.set_updated_at();

create trigger note_items_set_updated_at
before update on public.note_items
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.folders enable row level security;
alter table public.notes enable row level security;
alter table public.note_items enable row level security;

create policy "Users can read own profile"
on public.profiles for select
to authenticated
using (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

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

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.folders (user_id, name, color, position)
  values
    (new.id, 'Trabajo', '#8A9A7C', 1),
    (new.id, 'Personal', '#C29A7E', 2),
    (new.id, 'Ideas', '#A98DAF', 3)
  on conflict (user_id, name) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
