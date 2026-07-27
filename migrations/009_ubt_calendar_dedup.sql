-- ============================================================
-- Universidade BT — Calendário: remover linhas que duplicam cursos
-- Agora os cursos ativos entram AUTOMATICAMENTE no calendário do site.
-- A tabela ubt_calendar passa a guardar só linhas EXTRAS (turmas históricas).
-- Rode no projeto isolado.
-- ============================================================

delete from ubt_calendar
where curso in (
  'Curso Nacional Nível 1',
  'World Triathlon Level 1 Online',
  'World Triathlon Level 1 Híbrido'
);

-- Restam as extras/históricas: 'CBTri Nível 1 — Turma 1' e 'Curso Nacional Nível 2 — 1ª Turma'.
