-- ============================================================
-- 032 — Conteúdo programático do curso (para o verso do certificado) +
-- acesso do aluno ao próprio certificado por CPF + e-mail.
-- ⚠️ RODAR NO PROJETO ISOLADO do Academy (edbyrcyvlowcylljebmq).
-- Depende de 021 (ubt_acoes), 031 (ubt_certificados). Idempotente.
-- ============================================================

begin;

-- Conteúdo programático na configuração do curso: lista de {titulo, conteudo}.
alter table ubt_courses add column if not exists programa jsonb not null default '[]';
comment on column ubt_courses.programa is 'Conteúdo programático (grade): lista de {titulo, conteudo}. Vai para o verso do certificado.';

-- Acesso do aluno: devolve os certificados do próprio titular por CPF + e-mail
-- (os dois têm que bater). Só retorna campos seguros — nunca CPF de volta.
create or replace function ubt_cert_do_aluno(p_cpf text, p_email text) returns jsonb
  language sql stable security definer set search_path = public as $$
  with norm as (
    select regexp_replace(coalesce(p_cpf,''), '\D', '', 'g') as cpf,
           lower(btrim(coalesce(p_email,''))) as email
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'codigo', c.codigo, 'tipo', c.tipo, 'nome', c.nome,
           'titulo', (c.campos->>'titulo'), 'situacao', c.situacao,
           'emitido_em', c.emitido_em
         ) order by c.emitido_em desc), '[]'::jsonb)
  from ubt_certificados c, norm n
  where n.cpf <> '' and n.email <> ''
    and regexp_replace(coalesce(c.documento,''), '\D', '', 'g') = n.cpf
    and lower(btrim(coalesce(c.email,''))) = n.email;
$$;
grant execute on function ubt_cert_do_aluno(text, text) to anon, authenticated;

commit;
