# Supabase - Bloc

Scripts de base de datos para la fase 3.

## Orden recomendado

1. `migrations/0001_initial_schema.sql`
   - Crea tablas, indices, triggers, enum `note_type`, RLS y trigger de usuario nuevo.
   - Se ejecuta una vez en proyectos nuevos.

2. Crear usuario desde la app
   - El trigger `on_auth_user_created` crea `profiles` y carpetas base:
     `Trabajo`, `Personal`, `Ideas`.

3. `verify_schema.sql`
   - Verifica tablas, RLS, politicas, triggers y conteos.
   - No modifica datos.

4. `verify_user_bootstrap.sql`
   - Reemplazar `:user_id` por el UUID del usuario.
   - Verifica perfil y carpetas del usuario.

5. `seed.example.sql`
   - Opcional.
   - Reemplazar `:user_id` por el UUID del usuario.
   - Inserta una nota de texto y una checklist de prueba.

6. `setup_note_images.sql`
   - Crea la columna `notes.image_urls`.
   - Crea/configura el bucket publico `note-images`.
   - Crea politicas de Storage para subir y administrar imagenes por usuario.
   - Es seguro re-ejecutarlo.

## Migraciones

- `migrations/0001_initial_schema.sql`: esquema base.
- `migrations/0002_note_images.sql`: soporte de imagenes para proyectos nuevos o migraciones versionadas.

## Scripts de reparacion

Estos scripts son idempotentes y se usan si el proyecto real quedo a medias
durante pruebas manuales:

- `repair_auth_user_trigger.sql`: repara el trigger de alta de usuario.
- `repair_notes_rls.sql`: repara politicas RLS de `notes` y `note_items`.
- `repair_folders_rls.sql`: repara politicas RLS de `folders`.
- `repair_note_folders.sql`: asigna `Personal` a notas antiguas sin carpeta.

## Notas

- Los scripts de reparacion pueden mostrar una advertencia de Supabase por usar
  `drop policy if exists`. No eliminan datos de usuario.
- La app usa borrado logico: las notas eliminadas conservan fila con
  `deleted_at` y dejan de aparecer en Home.
- Las imagenes se guardan en Storage bajo la ruta `{user_id}/{note_id}/archivo`.
- No guardar llaves reales dentro del repositorio. Usar `--dart-define`.
