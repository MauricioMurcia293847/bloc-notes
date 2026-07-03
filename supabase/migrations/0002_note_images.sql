alter table public.notes
add column if not exists image_urls text[] not null default '{}';

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'note-images',
  'note-images',
  true,
  5242880,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heic',
    'image/heif'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read note images" on storage.objects;
drop policy if exists "Users can upload own note images" on storage.objects;
drop policy if exists "Users can update own note images" on storage.objects;
drop policy if exists "Users can delete own note images" on storage.objects;

create policy "Public can read note images"
on storage.objects for select
using (bucket_id = 'note-images');

create policy "Users can upload own note images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'note-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update own note images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'note-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'note-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete own note images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'note-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
