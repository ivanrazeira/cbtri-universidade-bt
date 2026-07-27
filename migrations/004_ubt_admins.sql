-- ============================================================
-- Universidade BT — Controle de administradores (Fase 2)
-- Restringe ESCRITA (cursos/calendário/docentes/waitlist/Storage) apenas
-- a contas listadas em ubt_admins. Como o projeto Supabase é compartilhado
-- com a plataforma, isto impede que outros usuários autenticados editem.
-- Leitura pública do site continua igual.
-- Rode DEPOIS de 001/002 (003 é opcional — este arquivo o substitui/reforça).
-- ============================================================

-- ---------- Tabela de admins ----------
create table if not exists ubt_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  created_at timestamptz not null default now()
);
alter table ubt_admins enable row level security;

-- Cada usuário autenticado pode verificar a própria condição de admin (usado pelo painel)
drop policy if exists ubt_admins_self_read on ubt_admins;
create policy ubt_admins_self_read on ubt_admins
  for select to authenticated using (user_id = auth.uid());

-- ---------- Helper: a conta atual é admin? ----------
create or replace function ubt_is_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from ubt_admins where user_id = auth.uid());
$$;

-- ---------- Refazer políticas de conteúdo (escrita só p/ admin) ----------
drop policy if exists ubt_courses_staff_all  on ubt_courses;
drop policy if exists ubt_faculty_staff_all  on ubt_faculty;
drop policy if exists ubt_calendar_staff_all on ubt_calendar;
drop policy if exists ubt_waitlist_staff_all on ubt_waitlist;

create policy ubt_courses_admin_all  on ubt_courses  for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
create policy ubt_faculty_admin_all  on ubt_faculty  for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
create policy ubt_calendar_admin_all on ubt_calendar for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
create policy ubt_waitlist_admin_all on ubt_waitlist for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());

-- ---------- Storage: escrita só p/ admin (substitui as de 003) ----------
drop policy if exists "ubt_storage_authenticated_insert" on storage.objects;
drop policy if exists "ubt_storage_authenticated_update" on storage.objects;
drop policy if exists "ubt_storage_authenticated_delete" on storage.objects;

create policy "ubt_storage_admin_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'ubt' and ubt_is_admin());
create policy "ubt_storage_admin_update" on storage.objects for update to authenticated
  using (bucket_id = 'ubt' and ubt_is_admin()) with check (bucket_id = 'ubt' and ubt_is_admin());
create policy "ubt_storage_admin_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'ubt' and ubt_is_admin());

-- ---------- Adiciona Ivan como admin (pela conta existente da plataforma) ----------
insert into ubt_admins (user_id, email)
select id, email from auth.users where email = 'ivan.razeira@cbtri.org.br'
on conflict (user_id) do nothing;

-- Para adicionar outro admin depois:
--   insert into ubt_admins (user_id, email)
--   select id, email from auth.users where email = 'fulano@cbtri.org.br'
--   on conflict do nothing;
