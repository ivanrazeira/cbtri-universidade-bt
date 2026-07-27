-- ============================================================
-- Universidade BT — Categoria do curso
-- Identifica se o curso é Curso Livre ou Certificação (Brasil/World Triathlon).
-- Rode no projeto isolado.
-- ============================================================

alter table ubt_courses
  add column if not exists categoria text
  check (categoria in ('certificacao_bt','certificacao_wt','livre'));

-- Backfill dos cursos existentes:
update ubt_courses set categoria = 'certificacao_wt' where intl = true and categoria is null;                       -- WT (internacional)
update ubt_courses set categoria = 'certificacao_bt' where intl = false and title ilike '%Nível%' and categoria is null; -- CBTri Nível 1/2
update ubt_courses set categoria = 'livre' where categoria is null;                                                  -- demais (ex.: Introdução)
