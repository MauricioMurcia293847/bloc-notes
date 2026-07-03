-- Verificacion despues de crear un usuario desde la app.
-- Reemplaza :user_id por el UUID del usuario en Authentication > Users.

select
  id,
  full_name,
  avatar_url,
  created_at
from public.profiles
where id = ':user_id';

select
  id,
  name,
  color,
  position,
  created_at
from public.folders
where user_id = ':user_id'
order by position, name;
