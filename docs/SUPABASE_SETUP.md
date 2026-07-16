# Supabase setup

Esta guia conecta el proyecto Flutter con un proyecto real de Supabase.

## 1. Crear proyecto

1. Entra a Supabase.
2. Crea un proyecto nuevo llamado `bloc-notes`.
3. Guarda la region, password de base de datos y organization usadas.
4. Espera a que el proyecto termine de aprovisionarse.

Proyecto actual:

- Dashboard: `https://supabase.com/dashboard/project/eguntjilflnbzmulzpam`
- API URL: `https://eguntjilflnbzmulzpam.supabase.co`

## 2. Aplicar migracion

En Supabase Dashboard:

1. Abre SQL Editor.
2. Crea un nuevo query.
3. Copia el contenido de `supabase/migrations/0001_initial_schema.sql`.
4. Ejecuta el query completo.
5. Verifica que existan estas tablas:
   - `profiles`
   - `folders`
   - `notes`
   - `note_items`

Luego aplica `supabase/setup_note_images.sql` para habilitar:

- columna `notes.image_urls`
- bucket `note-images`
- politicas de Storage para imagenes

## 3. Verificar RLS

En Table Editor, cada tabla debe tener RLS activo:

- `profiles`
- `folders`
- `notes`
- `note_items`

La migracion ya crea las politicas necesarias para que cada usuario solo acceda a sus propios datos.

## 4. Obtener llaves

En Supabase Dashboard:

1. Ve a Project Settings.
2. Abre API.
3. Copia:
   - Project URL
   - publishable key

No guardes la service role key en Flutter ni en Git.

## 5. Ejecutar app con Supabase

```powershell
flutter run -d emulator-5554 `
  --dart-define=SUPABASE_URL=https://eguntjilflnbzmulzpam.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

## 6. Auth

Para pruebas iniciales:

1. Ve a Authentication.
2. Habilita Email provider.
3. Decide si se requiere confirmar email para desarrollo.
4. Crea un usuario de prueba o registra uno desde la app cuando conectemos la UI.

## 7. Deep links de Auth

En Authentication > URL Configuration agrega:

```text
blocnotes://auth-callback
blocnotes://reset-password
```

`blocnotes://auth-callback` se usa para confirmar el correo al crear cuenta.
`blocnotes://reset-password` se usa para recuperacion de contrasena.

Los correos deben abrirse desde el emulador/dispositivo para que Android enrute
el enlace a la app.

## 8. Verificar usuario creado

Despues de registrar una cuenta desde la app:

1. Ve a Authentication > Users.
2. Copia el UUID del usuario.
3. Abre `supabase/verify_user_bootstrap.sql`.
4. Reemplaza `:user_id` por ese UUID.
5. Ejecuta el query.

Debe devolver:

- 1 fila en `profiles`.
- 3 filas en `folders`: Trabajo, Personal e Ideas.

## 9. Estado conectado

Actualmente estan conectados:

- Registro, login y cierre de sesion.
- Recuperacion de contrasena.
- CRUD de notas.
- Checklists.
- Filtros, busqueda y fijado.
- Papelera/restauracion.
- Perfil.
- Imagenes con Supabase Storage.
