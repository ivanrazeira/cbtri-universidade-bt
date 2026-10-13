-- 029 — Certificações de treinadores emitidas pela CBTri.
--
-- Fonte da verdade ACADÊMICA de quem concluiu cada nível (N1, N2, WT1). A
-- Plataforma Brasil Triathlon guarda só o perfil esportivo; o "certificado"
-- mora aqui (divisão Academy × Plataforma, módulo de Treinadores, 12/10/2026).
--
-- ⚠️ Este repositório é PÚBLICO. A carga com nomes, e-mails e CREF NÃO entra
-- no git: é um arquivo à parte, colado direto no SQL Editor.
--
-- Projeto: Supabase ISOLADO do Academy (edbyrcyvlowcylljebmq), não o da
-- plataforma.

begin;

create table if not exists ubt_certificacoes (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null check (char_length(btrim(nome)) between 3 and 150),
  email      text not null check (email = lower(btrim(email)) and email like '%@%.%'),
  cref       text check (char_length(cref) <= 40),
  nivel      text not null check (nivel in ('N1', 'N2', 'WT1')),
  turma      text not null check (char_length(turma) <= 60),
  ano        int  not null check (ano between 2015 and 2100),
  origem     text not null default 'planilha_cbtri',
  criado_em  timestamptz not null default now(),
  unique (email, nivel, turma)
);
create index if not exists idx_ubt_certificacoes_email on ubt_certificacoes(email);

-- Dado pessoal: só a equipe do Academy (ubt_admins) lê e escreve. Nada para a
-- chave publicável do site.
alter table ubt_certificacoes enable row level security;
drop policy if exists ubt_certificacoes_admin on ubt_certificacoes;
create policy ubt_certificacoes_admin on ubt_certificacoes
  for all using (ubt_is_admin()) with check (ubt_is_admin());
revoke all on ubt_certificacoes from anon;

commit;
