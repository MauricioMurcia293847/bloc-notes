-- Ejecuta este script solo si la verificacion de `on_auth_user_created`
-- no devuelve filas. Es seguro: no duplica el trigger si ya existe.

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

do $$
begin
  if not exists (
    select 1
    from pg_trigger trigger_info
    join pg_class event_table
      on event_table.oid = trigger_info.tgrelid
    join pg_namespace event_schema
      on event_schema.oid = event_table.relnamespace
    where not trigger_info.tgisinternal
      and event_schema.nspname = 'auth'
      and event_table.relname = 'users'
      and trigger_info.tgname = 'on_auth_user_created'
  ) then
    create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
  end if;
end;
$$;
