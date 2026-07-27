-- ============================================================
-- Universidade BT — Correção: insert público na waitlist
-- A publishable key não resolve para o papel 'anon' neste projeto,
-- então políticas escopadas "to anon" não pegam. Usamos PUBLIC
-- (sem cláusula de papel), igual às políticas de leitura que já funcionam.
-- ============================================================

grant insert on table ubt_waitlist to public;

drop policy if exists ubt_waitlist_public_insert on ubt_waitlist;
create policy ubt_waitlist_public_insert on ubt_waitlist
  for insert
  with check (true);   -- PUBLIC: qualquer visitante pode se inscrever (leitura segue só p/ admin)
