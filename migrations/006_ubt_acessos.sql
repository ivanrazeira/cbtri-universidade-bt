-- ============================================================
-- Universidade BT — Controle de acessos (projeto isolado)
-- Fecha a brecha: edição passa a exigir estar na lista ubt_admins,
-- não basta estar autenticado. Habilita a gestão de acessos pelo admin.
--
-- ORDEM IMPORTANTE (evitar lockout):
--   1) Crie SEU usuário admin em Authentication → Users → Add user (Auto Confirm)
--   2) SÓ ENTÃO rode este arquivo (ele te insere na lista pelo e-mail)
-- ============================================================

-- ---------- Lista de acessos ----------
create table if not exists ubt_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  nome       text,
  role       text not null default 'admin',   -- futuro: 'admin' | 'editor'
  created_at timestamptz not null default now()
);
alter table ubt_admins enable row level security;

create or replace function ubt_is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from ubt_admins where user_id = auth.uid());
$$;

-- Admins enxergam e gerenciam a lista de acessos; cada um vê a própria linha
drop policy if exists ubt_admins_read   on ubt_admins;
drop policy if exists ubt_admins_write  on ubt_admins;
create policy ubt_admins_read  on ubt_admins for select to authenticated using (ubt_is_admin() or user_id = auth.uid());
create policy ubt_admins_write on ubt_admins for all    to authenticated using (ubt_is_admin()) with check (ubt_is_admin());

-- ---------- Conteúdo: edição só p/ quem está na lista ----------
drop policy if exists ubt_courses_staff_all  on ubt_courses;
drop policy if exists ubt_faculty_staff_all  on ubt_faculty;
drop policy if exists ubt_calendar_staff_all on ubt_calendar;
drop policy if exists ubt_waitlist_staff_all on ubt_waitlist;
create policy ubt_courses_admin_all  on ubt_courses  for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
create policy ubt_faculty_admin_all  on ubt_faculty  for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
create policy ubt_calendar_admin_all on ubt_calendar for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
create policy ubt_waitlist_admin_all on ubt_waitlist for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());

-- ---------- Storage: escrita só p/ admin ----------
drop policy if exists "ubt_storage_authenticated_insert" on storage.objects;
drop policy if exists "ubt_storage_authenticated_update" on storage.objects;
drop policy if exists "ubt_storage_authenticated_delete" on storage.objects;
create policy "ubt_storage_admin_insert" on storage.objects for insert to authenticated with check (bucket_id='ubt' and ubt_is_admin());
create policy "ubt_storage_admin_update" on storage.objects for update to authenticated using (bucket_id='ubt' and ubt_is_admin()) with check (bucket_id='ubt' and ubt_is_admin());
create policy "ubt_storage_admin_delete" on storage.objects for delete to authenticated using (bucket_id='ubt' and ubt_is_admin());

-- ---------- Bootstrap: adiciona Ivan (rode DEPOIS de criar o usuário dele) ----------
insert into ubt_admins (user_id, email, nome, role)
select id, email, 'Ivan Razeira', 'admin' from auth.users where email = 'ivan.razeira@cbtri.org.br'
on conflict (user_id) do nothing;
