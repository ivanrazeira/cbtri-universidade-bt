-- ============================================================
-- 033 — Facilitador: acesso RESTRITO ao próprio (decisão 18/11/2026).
-- Deixa de ler diretamente ubt_acoes / beneficiários de terceiros / eventos
-- (receita, retenção CBTri, valores de outras partes, log). Passa a ver apenas,
-- por uma RPC segura: a oferta do curso, o SEU recebimento e os certificados
-- emitidos (sem CPF). ⚠️ Projeto isolado edbyrcyvlowcylljebmq.
-- Depende de 027/028 (políticas do facilitador) e 031 (certificados). Idempotente.
-- ============================================================

begin;

-- 1) Remove o acesso DIRETO do facilitador às tabelas sensíveis.
drop policy if exists ubt_acoes_facilitador_read              on ubt_acoes;
drop policy if exists ubt_acao_beneficiarios_facilitador_read on ubt_acao_beneficiarios;
drop policy if exists ubt_acao_eventos_facilitador_read       on ubt_acao_eventos;
-- (admins seguem com acesso total pelas políticas *_admin_all; ubt_cert_validar e
--  ubt_cert_do_aluno continuam públicas e seguras.)

-- 2) Painel do facilitador: só o que é dele. SECURITY DEFINER, escopo por e-mail.
create or replace function ubt_painel_facilitador() returns jsonb
  language sql stable security definer set search_path = public as $$
  with meu as (select ubt_email() as email),
  minhas as (
    select distinct b.acao_id
    from ubt_acao_beneficiarios b, meu
    where meu.email <> '' and lower(b.email) = meu.email
  )
  select jsonb_build_object(
    'acoes', coalesce((select jsonb_agg(jsonb_build_object(
        'id', a.id, 'titulo', a.titulo, 'turma_numero', a.turma_numero, 'formato', a.formato,
        'carga_horaria', a.carga_horaria, 'modalidade', a.modalidade,
        'inscricoes_abertura', a.inscricoes_abertura, 'inscricoes_encerramento', a.inscricoes_encerramento,
        'status', a.status, 'lotes', a.lotes
      ) order by a.id) from ubt_acoes a where a.id in (select acao_id from minhas)), '[]'::jsonb),
    'recebimentos', coalesce((select jsonb_agg(jsonb_build_object(
        'acao_id', b.acao_id, 'nome', b.nome, 'funcao_portaria', b.funcao_portaria,
        'modalidade', b.modalidade, 'valor', b.valor, 'percentual', b.percentual,
        'forma_pagamento', b.forma_pagamento, 'valor_devido', b.valor_devido, 'pago', b.pago
      )) from ubt_acao_beneficiarios b, meu where meu.email <> '' and lower(b.email) = meu.email), '[]'::jsonb),
    'certificados', coalesce((select jsonb_agg(jsonb_build_object(
        'acao_id', c.acao_id, 'codigo', c.codigo, 'nome', c.nome, 'titulo', (c.campos->>'titulo'),
        'situacao', c.situacao, 'emitido_em', c.emitido_em
      ) order by c.nome) from ubt_certificados c
      where c.tipo = 'participacao' and c.acao_id in (select acao_id from minhas)), '[]'::jsonb)
  );
$$;
grant execute on function ubt_painel_facilitador() to authenticated;

commit;
