-- ============================================================
-- Universidade BT — Lista de espera: permitir inscrição pública
-- Garante que visitantes (role anon) possam INSERIR na waitlist.
-- Leitura continua restrita a admins (política ubt_waitlist_admin_all).
-- Rode no projeto isolado.
-- ============================================================

alter table ubt_waitlist enable row level security;

-- Concede o privilégio de INSERT ao papel anônimo/autenticado (base para o RLS agir)
grant insert on table ubt_waitlist to anon, authenticated;

drop policy if exists ubt_waitlist_public_insert on ubt_waitlist;
create policy ubt_waitlist_public_insert on ubt_waitlist
  for insert to anon, authenticated
  with check (true);
