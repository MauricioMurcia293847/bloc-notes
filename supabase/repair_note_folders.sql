-- Asigna la carpeta Personal a notas existentes que quedaron sin folder_id.
-- Es seguro re-ejecutarlo: solo actualiza notas propias sin carpeta.

update public.notes note
set folder_id = folder.id
from public.folders folder
where note.folder_id is null
  and folder.user_id = note.user_id
  and folder.name = 'Personal';

select
  note.id,
  note.title,
  folder.name as folder_name,
  note.is_pinned,
  note.updated_at
from public.notes note
left join public.folders folder
  on folder.id = note.folder_id
where note.deleted_at is null
order by note.updated_at desc;
