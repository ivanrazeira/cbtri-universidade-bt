-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Fluxo administrativo-financeiro dos cursos da Brasil Triathlon Academy.
-- Base legal: Instrução Normativa nº 001/2026 + Portaria de Parâmetros nº 07/2026.
-- Substitui o rascunho 018 (nunca aplicado). Idempotente.
-- Depende de: 001 (ubt_set_updated_at), 006 (ubt_admins, ubt_is_admin).
-- ============================================================

-- ---------- Papéis funcionais (IN Art. 14 / segregação Art. 15) ----------
alter table ubt_admins add column if not exists papeis text[] not null default '{}';
-- vocabulário: coordenacao | direcao_tecnica | direcao_geral | administrativo | adm_financeiro | presidencia
create or replace function ubt_tem_papel(p text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from ubt_admins where user_id = auth.uid() and p = any(papeis));
$$;

-- ============================================================
-- 1) PARÂMETROS DA PORTARIA — TIPOS DE OFERTA (Anexo I e I.2)  [editável]
-- ============================================================
create table if not exists ubt_oferta_tipos (
  id                text primary key,          -- cbtri_n1 | cbtri_n2 | wt_l1 | livre | oficiais
  nome              text not null,
  modalidade        text not null,             -- 'A' (hora-aula/oferta) | 'B' (% receita líquida)
  chancela_internacional boolean not null default false,
  organismo         text,
  -- Modalidade A (valores por oferta, em R$)
  valor_principal   numeric,
  valor_colaborador numeric,
  -- Modalidade B (percentuais sobre receita líquida)
  pct_facilitadores numeric,                   -- conjunto dos facilitadores
  pct_mediador      numeric,
  -- referências (Anexo I.2)
  preco_ref         numeric,
  turma_prevista    integer,
  minimo_pagantes   integer,
  bolsas_max        integer not null default 5,
  bolsas_tipo       text default 'integral',   -- 'integral' | '50pct'
  carga_horaria_ref text,
  retencao_min_pct  numeric not null default 30,
  observacao        text,
  ordem             int not null default 0,
  ativo             boolean not null default true,
  updated_at        timestamptz not null default now()
);
drop trigger if exists ubt_oferta_tipos_updated_at on ubt_oferta_tipos;
create trigger ubt_oferta_tipos_updated_at before update on ubt_oferta_tipos
  for each row execute function ubt_set_updated_at();

insert into ubt_oferta_tipos
 (id, nome, modalidade, chancela_internacional, organismo, valor_principal, valor_colaborador, pct_facilitadores, pct_mediador, preco_ref, turma_prevista, minimo_pagantes, bolsas_max, bolsas_tipo, retencao_min_pct, observacao, ordem)
values
 ('cbtri_n1','CBTri Nível 1','A',false,null, 1700,1100, null,null, 450, 40, 15, 5,'integral',30,'Valores por oferta',1),
 ('cbtri_n2','CBTri Nível 2','A',false,null, 2000,1300, null,null, 900, 30, 10, 5,'integral',30,'Valores por oferta',2),
 ('wt_l1','World Triathlon Level 1','A',true,'World Triathlon', 10000,null, null,null, 3300, 20, 8, 5,'50pct',30,'R$ 10.000 para o conjunto dos facilitadores; divisão no plano econômico. 8 pagantes integrais + 5 bolsas de 50%',3),
 ('livre','Curso Livre','B',false,null, null,null, 30,10, 500, 30, 15, 5,'integral',30,'Facilitadores 30% (conjunto) + Mediador 10% da receita líquida; CBTri retenção mínima 30%',4),
 ('oficiais','Oficiais Técnicos','B',false,null, null,null, 30,null, 150, null, 15, 5,'integral',30,'Até 30% para o conjunto dos facilitadores; divisão 100 / 70-30 / 50-50 conforme carga e responsabilidade',5)
on conflict (id) do nothing;

-- ============================================================
-- 2) ETAPAS DO FLUXO (IN Art. 14 competências + Portaria Art. 10 prazos)  [ref]
-- ============================================================
create table if not exists ubt_fluxo_etapas (
  etapa            text primary key,   -- chave do estado
  ordem            int not null,
  nome             text not null,
  papel            text not null,      -- papel responsável (base; escalona por Art. 15)
  produto          text not null,
  prazo_dias_uteis integer,
  prazo_referencia text,               -- marco a partir do qual conta o prazo
  observacao       text
);
insert into ubt_fluxo_etapas (etapa, ordem, nome, papel, produto, prazo_dias_uteis, prazo_referencia, observacao) values
 ('proposicao',        1,'Proposição da ação e do plano econômico','coordenacao','Plano econômico da ação', null,null,'Coordenação da Brasil Triathlon Academy'),
 ('homologacao_docente',2,'Homologação do corpo docente e da carga horária','direcao_tecnica','Ato de homologação', null,null,null),
 ('aprovacao_plano',   3,'Aprovação do plano econômico','direcao_geral','Aprovação formal', 15,'antes_abertura_inscricoes','Até 15 dias úteis ANTES da abertura das inscrições'),
 ('inscricoes',        4,'Operacionalização e consolidação das inscrições','administrativo','Relatório de inscrições (inscrições, taxas e custos)', 10,'encerramento_acao','10 dias úteis do encerramento da ação'),
 ('ateste',            5,'Ateste da execução docente','direcao_tecnica','Ateste de horas-aula/entregas', 5,'consolidacao','5 dias úteis da consolidação'),
 ('apuracao',          6,'Apuração e conferência financeira','adm_financeiro','Demonstrativo de resultado', 5,'ateste','5 dias úteis do ateste; privativo do Adm-Financeiro (Art.15 §4)'),
 ('autorizacao',       7,'Autorização do pagamento','direcao_geral','Autorização', 3,'demonstrativo','3 dias úteis do demonstrativo'),
 ('execucao',          8,'Execução do pagamento','adm_financeiro','Comprovante', 15,'autorizacao','15 dias úteis da autorização; condicionado ao repasse da plataforma')
on conflict (etapa) do nothing;

-- ============================================================
-- 3) AÇÃO EDUCACIONAL + PLANO ECONÔMICO (IN Art. 17; Portaria Anexo I/II)
-- ============================================================
create table if not exists ubt_acoes (
  id                 bigint generated always as identity primary key,
  tipo_oferta_id     text references ubt_oferta_tipos(id),
  course_id          bigint references ubt_courses(id) on delete set null,
  titulo             text not null,
  resumo             text,                          -- breve descrição: o que é
  formato            text,                          -- presencial|online|sincrono|assincrono|hibrido
  categoria          text,                          -- formacao_certificacao | livre
  chancela_internacional boolean not null default false,
  organismo          text,
  modalidade         text not null default 'A',     -- A | B
  -- economia da inscrição
  preco_inscricao    numeric,
  taxa_plataforma_pct numeric not null default 10,
  taxa_tratamento    text,                          -- 'repassada' (<=1000) | 'absorvida' (>1000)
  retencao_min_pct   numeric not null default 30,
  carga_horaria      text,
  -- turma e bolsas
  pagantes_previstos integer,
  bolsas_qtd         integer not null default 0,
  bolsas_tipo        text,                          -- integral | 50pct
  numero_minimo      integer,                       -- mínimo operacional (Art. 13)
  data_limite_cancelamento date,
  inscricoes_abertura     date,
  inscricoes_encerramento date,
  -- custos e obrigações
  custos_diretos     jsonb not null default '[]',   -- [{rubrica, valor}]
  -- chanceladas (Portaria Art. 8)
  cambio_ref         numeric,
  cambio_data        date,
  provisao_me_pct    numeric default 30,
  obrigacoes_terceiros jsonb not null default '[]', -- [{item, valor_usd|valor, tipo}]
  -- plano econômico PROJETADO (auto-calculado; editável)
  receita_bruta_proj    numeric,
  deducoes_proj         numeric,
  receita_liquida_proj  numeric,
  remuneracao_docente_proj numeric,
  retencao_proj_pct     numeric,
  ponto_equilibrio      integer,
  -- apuração REAL (pós-ação)
  inscricoes_encerradas boolean not null default false,
  repasse_confirmado    boolean not null default false,
  receita_bruta_real    numeric,
  receita_liquida_real  numeric,
  retencao_apurada      numeric,
  -- estado do fluxo
  fase   text not null default 'proposicao' references ubt_fluxo_etapas(etapa),
  status text not null default 'rascunho',          -- rascunho|em_andamento|aprovada|concluida|cancelada
  observacoes text,
  created_by  uuid,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
drop trigger if exists ubt_acoes_updated_at on ubt_acoes;
create trigger ubt_acoes_updated_at before update on ubt_acoes
  for each row execute function ubt_set_updated_at();

-- ============================================================
-- 4) BENEFICIÁRIOS / FACILITADORES (IN Art. 4, 6, 16, 19; Portaria Art. 9)
-- ============================================================
create table if not exists ubt_acao_beneficiarios (
  id             bigint generated always as identity primary key,
  acao_id        bigint not null references ubt_acoes(id) on delete cascade,
  faculty_id     bigint references ubt_faculty(id) on delete set null,
  nome           text not null,
  categoria_vinculo text not null default 'externo',  -- externo | interno | dirigente (Art.4)
  funcao_portaria   text,                             -- principal | colaborador | mediador
  vinculo_desc   text,                                -- descrição da natureza do vínculo (Art.19 I)
  atividade_desc text,                                -- descrição da atividade docente (Art.19 II)
  modalidade     text not null default 'A',           -- A | B
  valor          numeric,                             -- Modalidade A (por oferta/entrega)
  percentual     numeric,                             -- Modalidade B (% receita líquida)
  forma_pagamento text,                               -- rpa | nf (Portaria Art. 9)
  valor_devido   numeric,                             -- resultado da memória de cálculo
  memoria_calculo text,                               -- Art. 19 III
  -- gates documentais
  homologado             boolean not null default false, -- Art. 6 II / Art. 14
  decl_nao_sobreposicao  boolean not null default false, -- Art. 6 III (interno)
  decl_conflito          boolean not null default false, -- Art. 16
  termo_adesao           boolean not null default false, -- Art. 9 (Modalidade B)
  -- ateste e pagamento
  ateste_ok    boolean not null default false,        -- Art. 19 IV / 15
  ateste_por   uuid, ateste_em timestamptz,
  pago         boolean not null default false, pago_em timestamptz, comprovante text,
  created_at   timestamptz not null default now()
);
create index if not exists ubt_acao_benef_acao on ubt_acao_beneficiarios(acao_id);

-- ============================================================
-- 5) TRILHA DE AUDITORIA / APROVAÇÕES (rastreabilidade — Art. 14/15)
-- ============================================================
create table if not exists ubt_acao_eventos (
  id          bigint generated always as identity primary key,
  acao_id     bigint not null references ubt_acoes(id) on delete cascade,
  etapa       text not null,
  decisao     text not null,          -- concluido|aprovado|reprovado|cancelado|observacao
  papel       text,                   -- papel sob o qual o responsável agiu
  produto     text,                   -- referência/nota/arquivo do produto da etapa
  observacao  text,
  prazo_limite date,                  -- prazo-alvo desta etapa (Portaria Art. 10)
  user_id     uuid,
  user_email  text,
  created_at  timestamptz not null default now()
);
create index if not exists ubt_acao_eventos_acao on ubt_acao_eventos(acao_id, created_at);

-- ============================================================
-- 6) RLS — leitura/escrita apenas para contas do painel (ubt_is_admin).
--    A segregação por papel (quem pode cada etapa) é aplicada no app e
--    registrada em ubt_acao_eventos (auditável).
-- ============================================================
alter table ubt_oferta_tipos        enable row level security;
alter table ubt_fluxo_etapas        enable row level security;
alter table ubt_acoes               enable row level security;
alter table ubt_acao_beneficiarios  enable row level security;
alter table ubt_acao_eventos        enable row level security;

do $$
declare t text;
begin
  foreach t in array array['ubt_oferta_tipos','ubt_fluxo_etapas','ubt_acoes','ubt_acao_beneficiarios','ubt_acao_eventos']
  loop
    execute format('drop policy if exists %I_admin_all on %I', t, t);
    execute format('create policy %I_admin_all on %I for all to authenticated using (ubt_is_admin()) with check (ubt_is_admin())', t, t);
  end loop;
end $$;

-- ---------- (opcional) marque seus papéis para testar a segregação ----------
-- update ubt_admins set papeis = ARRAY['direcao_geral','coordenacao']
--   where email = 'ivan.razeira@cbtri.org.br';
