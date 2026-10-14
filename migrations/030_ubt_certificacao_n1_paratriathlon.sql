-- 030 — Novo nível de certificação: Treinador Nível 1 com habilitação em
-- Paratriathlon (pedido do Ivan, 14/10/2026). Código: N1P.
--
-- É uma certificação à parte (turma própria), não uma marca em cima do N1:
-- quem tem as duas aparece com as duas.

begin;

do $$
begin
  if to_regclass('public.ubt_certificacoes') is null or to_regprocedure('public.ubt_is_admin()') is null then
    raise exception 'PROJETO ERRADO: esta migration é do Academy (projeto edbyrcyvlowcylljebmq), e precisa da 029 antes. Troque o projeto no painel do Supabase e rode de novo.';
  end if;
end $$;

-- Troca o CHECK do nível, seja qual for o nome que o Postgres deu a ele.
do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.ubt_certificacoes'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%nivel%'
  loop
    execute format('alter table public.ubt_certificacoes drop constraint %I', c);
  end loop;
end $$;

alter table public.ubt_certificacoes
  add constraint ubt_certificacoes_nivel_check check (nivel in ('N1', 'N2', 'WT1', 'N1P'));

commit;
