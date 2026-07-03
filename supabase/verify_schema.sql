-- Verificacion segura del esquema Bloc.
-- Este script no modifica datos; solo confirma tablas, RLS y politicas.

select 'tables' as check_group;

select
  table_schema,
  table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('profiles', 'folders', 'notes', 'note_items')
order by table_name;

select 'rls_enabled' as check_group;

select
  schemaname,
  tablename,
  rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles', 'folders', 'notes', 'note_items')
order by tablename;

select 'policies' as check_group;

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
  and tablename in ('profiles', 'folders', 'notes', 'note_items')
order by tablename, policyname;

select 'public_triggers' as check_group;

select
  trigger_schema,
  event_object_table,
  trigger_name
from information_schema.triggers
where trigger_schema in ('public', 'auth')
  and trigger_name in (
    'profiles_set_updated_at',
    'folders_set_updated_at',
    'notes_set_updated_at',
    'note_items_set_updated_at',
    'on_auth_user_created'
  )
order by event_object_table, trigger_name;

select 'auth_user_trigger' as check_group;

select
  event_schema.nspname as event_schema,
  event_table.relname as event_table,
  trigger_info.tgname as trigger_name,
  trigger_info.tgenabled as enabled
from pg_trigger trigger_info
join pg_class event_table
  on event_table.oid = trigger_info.tgrelid
join pg_namespace event_schema
  on event_schema.oid = event_table.relnamespace
where not trigger_info.tgisinternal
  and event_schema.nspname = 'auth'
  and event_table.relname = 'users'
  and trigger_info.tgname = 'on_auth_user_created';

select 'table_counts' as check_group;

select 'profiles' as table_name, count(*) as total from public.profiles
union all
select 'folders', count(*) from public.folders
union all
select 'notes_active', count(*) from public.notes where deleted_at is null
union all
select 'notes_deleted', count(*) from public.notes where deleted_at is not null
union all
select 'note_items', count(*) from public.note_items;
