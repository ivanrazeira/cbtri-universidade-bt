-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Configuração da oferta: turma, lotes de inscrição e faixa de valores.
-- Depende da 021. Idempotente.
-- ============================================================

alter table ubt_acoes add column if not exists turma_numero integer;       -- 1 = 1ª turma, 2 = 2ª, ...
alter table ubt_acoes add column if not exists lotes        jsonb not null default '[]';
  -- [{nome:'Lote 1', valor:500, vagas:15, ate:'2026-09-30'}]
alter table ubt_acoes add column if not exists valor_min    numeric;       -- menor valor de inscrição (menor lote)
alter table ubt_acoes add column if not exists valor_max    numeric;       -- maior valor de inscrição (maior lote)

comment on column ubt_acoes.lotes is 'Lotes de inscrição: lista de {nome, valor, vagas, ate}. O preço vigente e o valor_min/valor_max derivam daqui.';
