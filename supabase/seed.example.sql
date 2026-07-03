-- Datos semilla opcionales para pruebas manuales.
-- Reemplaza :user_id por el UUID de auth.users del usuario de prueba.
-- Recomendacion: ejecuta primero la app y crea el usuario para que existan
-- sus carpetas Trabajo, Personal e Ideas.

with user_folders as (
  select id, name
  from public.folders
  where user_id = ':user_id'
),
inserted_text_note as (
  insert into public.notes (
    user_id,
    folder_id,
    title,
    body,
    note_type,
    is_pinned
  )
  values (
    ':user_id',
    (select id from user_folders where name = 'Personal'),
    'Nota de prueba',
    'Esta nota valida lectura, edicion, carpeta y borrado logico.',
    'text',
    false
  )
  returning id
),
inserted_checklist_note as (
  insert into public.notes (
    user_id,
    folder_id,
    title,
    body,
    note_type,
    is_pinned
  )
  values (
    ':user_id',
    (select id from user_folders where name = 'Trabajo'),
    'Checklist de prueba',
    '',
    'checklist',
    true
  )
  returning id
)
insert into public.note_items (note_id, content, is_done, position)
values
  ((select id from inserted_checklist_note), 'Crear nota checklist', true, 1),
  ((select id from inserted_checklist_note), 'Editar elementos', false, 2),
  ((select id from inserted_checklist_note), 'Validar filtros', false, 3);

select
  note.id,
  note.title,
  note.note_type,
  folder.name as folder_name,
  note.is_pinned,
  note.deleted_at
from public.notes note
left join public.folders folder
  on folder.id = note.folder_id
where note.user_id = ':user_id'
order by note.updated_at desc;
