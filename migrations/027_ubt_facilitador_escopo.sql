-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Acesso ESCOPADO do facilitador: enxerga apenas as ações em que é parte
-- (casamento por e-mail), sem ser admin. Depende de 021 e 026. Idempotente.
-- ============================================================

-- e-mail do usuário logado (minúsculo). '' quando anônimo.
create or replace function ubt_email() returns text language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email', ''));
$$;

-- Facilitador lê SOMENTE as ações onde é uma das partes (por e-mail).
-- Política PERMISSIVA adicional (soma com a admin_all via OR).
drop policy if exists ubt_acoes_facilitador_read on ubt_acoes;
create policy ubt_acoes_facilitador_read on ubt_acoes
  for select to authenticated
  using (
    ubt_email() <> '' and exists (
      select 1 from ubt_acao_beneficiarios b
      where b.acao_id = ubt_acoes.id and lower(b.email) = ubt_email()
    )
  );

-- Facilitador lê SOMENTE a(s) própria(s) linha(s) de rateio (seu valor).
drop policy if exists ubt_acao_beneficiarios_facilitador_read on ubt_acao_beneficiarios;
create policy ubt_acao_beneficiarios_facilitador_read on ubt_acao_beneficiarios
  for select to authenticated
  using ( ubt_email() <> '' and lower(email) = ubt_email() );

-- OBS: facilitador NÃO recebe política para ubt_acao_inscritos (lista de alunos/CPF),
-- ubt_acao_eventos nem ubt_admins — continuam admin-only. Assim ele não vê dados de terceiros.
