-- ============================================================
-- ⚠️⚠️  LIMPEZA — RODAR SOMENTE NO PROJETO ANTIGO (PLATAFORMA)  ⚠️⚠️
--
--   Projeto CORRETO p/ rodar:  pxsrbyhsqpkcyxpermhp  (o da plataforma/ERP)
--   NÃO rode no isolado:        edbyrcyvlowcylljebmq  (é o da Universidade, EM PRODUÇÃO!)
--
-- Confirme no topo do SQL Editor que o projeto selecionado é o da PLATAFORMA
-- antes de executar. Este script apaga as tabelas ubt_ que foram criadas lá
-- por engano (a Universidade migrou para o projeto isolado).
-- ============================================================

drop table if exists ubt_waitlist cascade;
drop table if exists ubt_calendar cascade;
drop table if exists ubt_faculty  cascade;
drop table if exists ubt_courses  cascade;
drop table if exists ubt_admins   cascade;   -- não existe lá, mas por segurança

drop function if exists ubt_is_admin()      cascade;   -- idem
drop function if exists ubt_set_updated_at() cascade;

-- Conferência (deve retornar 0 linhas):
select tablename from pg_tables where schemaname='public' and tablename like 'ubt_%';
