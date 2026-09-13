-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Importação do export de inscritos da TicketSports → demonstrativo/apuração
-- automática (IN 001/2026, Art. 21). Depende da 021. Idempotente.
-- ============================================================

-- Inscritos por ação (uma linha por inscrição do CSV da TicketSports)
create table if not exists ubt_acao_inscritos (
  id              bigint generated always as identity primary key,
  acao_id         bigint not null references ubt_acoes(id) on delete cascade,
  n_inscricao     text,                          -- coluna "N inscricao" (chave da TicketSports)
  nome            text,
  email           text,
  documento       text,                          -- CPF
  categoria       text,                          -- nome do curso na TicketSports
  lote            text,
  forma_pagamento text,
  data_pagamento  text,
  valor_inscricao numeric,                        -- [32] valor unitário
  valor_desconto  numeric,                        -- [33]
  valor_pago      numeric,                        -- [34] valor pago pelo inscrito (com taxa)
  taxa            numeric,                        -- [35] taxa participante (10%)
  valor_repasse   numeric,                        -- [36] repasse à CBTri  ← base da receita
  status          text,                           -- [53] status do pedido (Pago, ...)
  cancelado       boolean not null default false, -- possui data de cancelamento / estorno
  created_at      timestamptz not null default now(),
  unique (acao_id, n_inscricao)                   -- reimportar atualiza, não duplica
);
create index if not exists ubt_acao_inscritos_acao on ubt_acao_inscritos(acao_id);

-- Totais de apuração na ação (info; a receita/rateio já usam campos da 021)
alter table ubt_acoes add column if not exists valor_pago_total      numeric;  -- Σ valor pago pelos inscritos
alter table ubt_acoes add column if not exists taxa_plataforma_total numeric;  -- Σ taxa participante
alter table ubt_acoes add column if not exists inscritos_pagos       integer;  -- nº de inscrições pagas (não canceladas)
alter table ubt_acoes add column if not exists apurado_em            timestamptz;

-- RLS admin-only (igual às demais tabelas do fluxo)
alter table ubt_acao_inscritos enable row level security;
drop policy if exists ubt_acao_inscritos_admin_all on ubt_acao_inscritos;
create policy ubt_acao_inscritos_admin_all on ubt_acao_inscritos
  for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
