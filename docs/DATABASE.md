# Modelo de base de datos

Este documento define el modelo inicial para Supabase/PostgreSQL.

## Archivos de Fase 3

- `supabase/migrations/0001_initial_schema.sql`: esquema inicial, indices, triggers y politicas RLS.
- `supabase/migrations/0002_note_images.sql`: columna `image_urls`, bucket `note-images` y politicas de Storage.
- `supabase/setup_note_images.sql`: script manual idempotente para aplicar imagenes en el proyecto real.
- `supabase/verify_schema.sql`: verificacion de tablas, RLS, politicas, triggers y conteos.
- `supabase/verify_user_bootstrap.sql`: verificacion del perfil/carpetas de un usuario.
- `supabase/seed.example.sql`: datos opcionales de prueba para texto y checklist.
- `supabase/repair_*.sql`: scripts seguros para reparar RLS/triggers si el proyecto real quedo a medias durante pruebas manuales.
- `supabase/README.md`: orden recomendado para ejecutar/verificar los scripts.
- `.env.example`: nombres de variables que usara la app.

## Configuracion en Flutter

La app lee Supabase desde `--dart-define`, sin guardar secretos en Git.

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Si esos valores estan vacios, la app sigue funcionando en modo mock para desarrollo visual.

## profiles

Perfil publico asociado a cada usuario autenticado.

| Campo | Tipo | Notas |
| --- | --- | --- |
| id | uuid | PK, referencia a `auth.users.id` |
| full_name | text | Nombre del usuario |
| avatar_url | text | Opcional |
| created_at | timestamptz | Fecha de creacion |
| updated_at | timestamptz | Fecha de actualizacion |

## folders

Carpetas o categorias de notas.

| Campo | Tipo | Notas |
| --- | --- | --- |
| id | uuid | PK |
| user_id | uuid | FK a `auth.users.id` |
| name | text | Nombre visible |
| color | text | Opcional |
| created_at | timestamptz | Fecha de creacion |
| updated_at | timestamptz | Fecha de actualizacion |

## notes

Notas principales.

| Campo | Tipo | Notas |
| --- | --- | --- |
| id | uuid | PK |
| user_id | uuid | FK a `auth.users.id` |
| folder_id | uuid | FK opcional a `folders.id` |
| title | text | Titulo |
| body | text | Contenido principal |
| note_type | text | `text` o `checklist` |
| is_pinned | boolean | Nota fijada |
| image_urls | text[] | URLs publicas de imagenes en Supabase Storage |
| reminder_at | timestamptz | Opcional |
| deleted_at | timestamptz | Borrado logico |
| created_at | timestamptz | Fecha de creacion |
| updated_at | timestamptz | Fecha de actualizacion |

## note_items

Items para notas tipo checklist.

| Campo | Tipo | Notas |
| --- | --- | --- |
| id | uuid | PK |
| note_id | uuid | FK a `notes.id` |
| content | text | Texto del item |
| is_done | boolean | Estado del checkbox |
| position | integer | Orden visual |
| created_at | timestamptz | Fecha de creacion |
| updated_at | timestamptz | Fecha de actualizacion |

## Preferencias de RLS

Todas las tablas de usuario deben tener Row Level Security activo. Cada politica debe validar que `auth.uid()` coincida con `user_id` o con el propietario indirecto de la nota.

## Politicas incluidas

- Cada usuario puede leer, crear, editar y eliminar solo sus carpetas.
- Cada usuario puede leer, crear, editar y eliminar solo sus notas.
- Los items de checklist se autorizan mediante la nota propietaria.
- Cada usuario puede leer y actualizar solo su perfil.
- Las politicas se limitan al rol `authenticated`.

## Storage: note-images

Las imagenes de notas se guardan en Supabase Storage dentro del bucket publico
`note-images`.

Ruta usada por la app:

```text
{user_id}/{note_id}/{timestamp}.{extension}
```

Politicas incluidas:

- Lectura publica del bucket para poder renderizar miniaturas.
- Usuarios autenticados pueden subir solo a su carpeta `{auth.uid()}`.
- Usuarios autenticados pueden actualizar/eliminar solo objetos de su carpeta.

## Trigger de usuario nuevo

La migracion crea `public.handle_new_user()`, que genera automaticamente:

- Perfil del usuario.
- Carpetas iniciales: Trabajo, Personal e Ideas.

## Estado de Fase 3

Completado:

- Proyecto Supabase creado.
- Tablas relacionales creadas.
- Relaciones entre `users`, `profiles`, `folders`, `notes` y `note_items`.
- RLS probado con usuario real.
- Trigger de nuevo usuario probado.
- Carpetas base creadas automaticamente.
- Seed opcional documentado.
- Scripts de verificacion y reparacion organizados.
- Storage de imagenes configurado con bucket `note-images`.

Pendiente para fases posteriores:

- Gestion avanzada de carpetas desde la app.
- Recordatorios reales.
