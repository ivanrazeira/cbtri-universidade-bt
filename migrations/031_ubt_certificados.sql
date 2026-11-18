-- ============================================================
-- 031 — Motor de certificados da Academy (participação em curso + níveis).
-- Nos moldes do certificado do atleta da plataforma: o certificado é uma FOTO
-- CONGELADA (snapshot dos campos na emissão) + código + hash + QR + página
-- pública de validação. Correção = revogar e reemitir (nunca reescrever).
--
-- ⚠️ RODAR NO PROJETO ISOLADO do Academy (edbyrcyvlowcylljebmq), não na plataforma.
-- Depende de 021 (ubt_acoes), 022 (ubt_acao_inscritos), 029 (ubt_certificacoes).
-- ============================================================

begin;

do $$
begin
  if to_regclass('public.ubt_admins') is null or to_regprocedure('public.ubt_is_admin()') is null then
    raise exception 'PROJETO ERRADO: esta migration é do Academy (edbyrcyvlowcylljebmq). Troque o projeto no painel e rode de novo.';
  end if;
end $$;

create table if not exists ubt_certificados (
  id            uuid primary key default gen_random_uuid(),
  codigo        text not null unique,                 -- BTA-AAAA-NNNNNN
  tipo          text not null check (tipo in ('participacao','nivel')),
  ano           int  not null,
  sequencial    int  not null,
  -- origem (uma das duas, conforme o tipo)
  acao_id         bigint references ubt_acoes(id)        on delete set null,  -- participação (curso livre)
  certificacao_id uuid   references ubt_certificacoes(id) on delete set null, -- nível (N1/N2/WT1/N1P)
  -- titular
  nome          text not null,
  documento     text,                                 -- CPF (participação) — NUNCA exposto ao público
  email         text,
  -- snapshot renderizado (sem CPF) + prova de integridade
  campos        jsonb not null default '{}',
  hash_conteudo text,
  url_validacao text,
  -- estado
  situacao      text not null default 'valido' check (situacao in ('valido','revogado')),
  motivo_revogacao text,
  revogado_em   timestamptz,
  revogado_por  text,
  emitido_em    timestamptz not null default now(),
  emitido_por   text
);
create index if not exists idx_ubt_cert_acao on ubt_certificados(acao_id);
-- idempotência: não reemitir o mesmo titular para o mesmo curso/nível
create unique index if not exists uniq_cert_participacao on ubt_certificados(acao_id, documento)
  where tipo = 'participacao' and documento is not null;
create unique index if not exists uniq_cert_nivel on ubt_certificados(certificacao_id)
  where tipo = 'nivel';

-- Sequência atômica por ano (separada por ano, não reinicia dentro do ano).
create table if not exists ubt_certificado_seq (ano int primary key, ultimo int not null default 0);
create or replace function ubt_proximo_cert_seq(p_ano int) returns int
  language plpgsql security definer set search_path = public as $$
declare n int;
begin
  insert into ubt_certificado_seq(ano, ultimo) values (p_ano, 1)
    on conflict (ano) do update set ultimo = ubt_certificado_seq.ultimo + 1
    returning ultimo into n;
  return n;
end $$;

-- Dado pessoal: tabela admin-only. A chave publicável (anon) não lê a tabela.
alter table ubt_certificados enable row level security;
drop policy if exists ubt_certificados_admin on ubt_certificados;
create policy ubt_certificados_admin on ubt_certificados
  for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin());
revoke all on ubt_certificados from anon;

-- Validação PÚBLICA: RPC que devolve só campos seguros (sem CPF), pelo código.
-- É a única porta do anon aos dados do certificado.
create or replace function ubt_cert_validar(p_cod text) returns jsonb
  language sql stable security definer set search_path = public as $$
  select case when c.id is null then null else jsonb_build_object(
    'codigo',           c.codigo,
    'tipo',             c.tipo,
    'nome',             c.nome,
    'situacao',         c.situacao,
    'motivo_revogacao', c.motivo_revogacao,
    'emitido_em',       c.emitido_em,
    'hash_conteudo',    c.hash_conteudo,
    'campos',           (c.campos - 'documento' - 'cpf')  -- blindagem: remove CPF se tiver entrado no snapshot
  ) end
  from ubt_certificados c
  where upper(btrim(c.codigo)) = upper(btrim(coalesce(p_cod, '')));
$$;
grant execute on function ubt_cert_validar(text) to anon, authenticated;

commit;
