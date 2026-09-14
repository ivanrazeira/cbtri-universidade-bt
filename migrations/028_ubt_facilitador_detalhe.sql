-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Facilitador vê o DETALHE completo das suas ações (oferta, rateio, fluxo/log),
-- exceto a lista de alunos/CPF. Depende de 021, 026, 027. Idempotente.
-- ============================================================

-- Helper SECURITY DEFINER: o usuário logado é parte desta ação? (evita recursão de RLS)
create or replace function ubt_is_parte(p_acao bigint) returns boolean
language sql stable security definer set search_path = public as $$
  select ubt_email() <> '' and exists (
    select 1 from ubt_acao_beneficiarios b
    where b.acao_id = p_acao and lower(b.email) = ubt_email()
  );
$$;

-- Ações: facilitador lê as suas (via helper)
drop policy if exists ubt_acoes_facilitador_read on ubt_acoes;
create policy ubt_acoes_facilitador_read on ubt_acoes
  for select to authenticated using ( ubt_is_parte(id) );

-- Partes: facilitador vê TODAS as partes das suas ações (rateio completo)
drop policy if exists ubt_acao_beneficiarios_facilitador_read on ubt_acao_beneficiarios;
create policy ubt_acao_beneficiarios_facilitador_read on ubt_acao_beneficiarios
  for select to authenticated using ( ubt_is_parte(acao_id) );

-- Eventos (log do fluxo): facilitador vê o das suas ações
drop policy if exists ubt_acao_eventos_facilitador_read on ubt_acao_eventos;
create policy ubt_acao_eventos_facilitador_read on ubt_acao_eventos
  for select to authenticated using ( ubt_is_parte(acao_id) );

-- Definição das etapas do fluxo é referência (não sensível): liberar leitura a qualquer logado
drop policy if exists ubt_fluxo_etapas_read_auth on ubt_fluxo_etapas;
create policy ubt_fluxo_etapas_read_auth on ubt_fluxo_etapas
  for select to authenticated using ( true );

-- OBS: ubt_acao_inscritos (alunos/CPF) continua SEM política de facilitador — permanece oculto.
