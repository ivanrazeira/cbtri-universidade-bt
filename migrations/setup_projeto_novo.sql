-- ============================================================
-- Universidade BT — SETUP COMPLETO para projeto Supabase NOVO/ISOLADO
-- Rode este arquivo UMA vez no SQL Editor do projeto dedicado.
-- (schema + dados atuais + políticas de Storage). Bucket 'ubt' deve existir.
-- ============================================================

-- >>>>> 001 — SCHEMA <<<<<
-- ============================================================
-- Universidade BT — Schema inicial (Fase 1)
-- Tabelas prefixadas ubt_ para conviver no projeto Supabase do cbtri-platform.
-- Cobre: cursos, calendário, corpo docente e lista de espera.
-- (Matrículas / alunos / certificados virão em migration posterior — Fases 4 e 5.)
-- ============================================================

-- ---------- Função utilitária: updated_at automático ----------
create or replace function ubt_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- CURSOS
-- ============================================================
create table if not exists ubt_courses (
  id             bigint generated always as identity primary key,
  slug           text unique,
  title          text not null,
  status         text not null default 'soon'
                   check (status in ('soon','open','sold','done')),
  format         text,                       -- "100% Online", "Online + Presencial"...
  vagas          int,                        -- capacidade total (null = não exibe)
  vagas_ocupadas int  not null default 0,
  carga_horaria  text,
  descricao      text,
  featured       boolean not null default false,
  intl           boolean not null default false,
  periodo        text,
  inscricoes     text,
  link           text,                       -- link externo (TicketSports)
  cronograma     jsonb,                      -- {inscricoes, vagas, horarios[], encontros[], presencial{}}
  publico        text[],                     -- ex.: {"Atletas","Pais",...}
  ordem          int  not null default 0,
  ativo          boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists ubt_courses_ativo_ordem_idx on ubt_courses (ativo, ordem);

drop trigger if exists ubt_courses_updated_at on ubt_courses;
create trigger ubt_courses_updated_at
  before update on ubt_courses
  for each row execute function ubt_set_updated_at();

-- ============================================================
-- CORPO DOCENTE
-- ============================================================
create table if not exists ubt_faculty (
  id          bigint generated always as identity primary key,
  name        text not null,
  role        text,
  initials    text,
  badge       text,
  formacao    text[] not null default '{}',
  cert        text[] not null default '{}',
  experiencia text[] not null default '{}',   -- "exp" no front-end
  specs       text[] not null default '{}',
  link        text,                            -- Lattes / currículo
  photo_url   text,                            -- Supabase Storage (substitui base64)
  guest       boolean not null default false,
  ordem       int  not null default 0,
  ativo       boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists ubt_faculty_ativo_ordem_idx on ubt_faculty (ativo, ordem);

drop trigger if exists ubt_faculty_updated_at on ubt_faculty;
create trigger ubt_faculty_updated_at
  before update on ubt_faculty
  for each row execute function ubt_set_updated_at();

-- ============================================================
-- CALENDÁRIO (linhas independentes; podem referenciar um curso)
-- ============================================================
create table if not exists ubt_calendar (
  id          bigint generated always as identity primary key,
  curso       text not null,                   -- rótulo exibido
  course_id   bigint references ubt_courses(id) on delete set null,
  periodo     text,
  inscricoes  text,
  vagas       text,                            -- texto livre: "30/30", "20", "A definir"
  formato     text,
  status      text not null default 'soon'
                check (status in ('soon','open','sold','done')),
  ordem       int  not null default 0,
  ativo       boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists ubt_calendar_ativo_ordem_idx on ubt_calendar (ativo, ordem);

drop trigger if exists ubt_calendar_updated_at on ubt_calendar;
create trigger ubt_calendar_updated_at
  before update on ubt_calendar
  for each row execute function ubt_set_updated_at();

-- ============================================================
-- LISTA DE ESPERA (waitlist)
-- ============================================================
create table if not exists ubt_waitlist (
  id           bigint generated always as identity primary key,
  course_id    bigint references ubt_courses(id) on delete set null,
  course_title text,                           -- snapshot do título no momento
  nome         text not null,
  email        text not null,
  telefone     text,
  created_at   timestamptz not null default now()
);

create index if not exists ubt_waitlist_course_idx on ubt_waitlist (course_id);

-- ============================================================
-- RLS — Row Level Security
--   anon (público)      → SELECT em conteúdo ativo + INSERT na waitlist
--   authenticated (staff) → acesso total (gerência pelo admin)
-- ============================================================
alter table ubt_courses  enable row level security;
alter table ubt_faculty  enable row level security;
alter table ubt_calendar enable row level security;
alter table ubt_waitlist enable row level security;

-- Leitura pública (somente registros ativos)
create policy ubt_courses_public_read on ubt_courses
  for select using (ativo = true);
create policy ubt_faculty_public_read on ubt_faculty
  for select using (ativo = true);
create policy ubt_calendar_public_read on ubt_calendar
  for select using (ativo = true);

-- Waitlist: qualquer visitante pode se inscrever, ninguém lê pelo anon
create policy ubt_waitlist_public_insert on ubt_waitlist
  for insert with check (true);

-- Staff autenticado: acesso total
create policy ubt_courses_staff_all  on ubt_courses  for all to authenticated using (true) with check (true);
create policy ubt_faculty_staff_all  on ubt_faculty  for all to authenticated using (true) with check (true);
create policy ubt_calendar_staff_all on ubt_calendar for all to authenticated using (true) with check (true);
create policy ubt_waitlist_staff_all on ubt_waitlist for all to authenticated using (true) with check (true);

-- >>>>> 002 — SEED <<<<<
-- ============================================================
-- Universidade BT — Seed inicial (Fase 1)
-- Gerado a partir do conteúdo atual do index.html.
-- Rode DEPOIS de 001_ubt_schema.sql.
-- ============================================================

truncate table ubt_calendar, ubt_faculty, ubt_courses restart identity cascade;

-- ---------- CURSOS ----------
insert into ubt_courses (title,status,format,vagas,carga_horaria,descricao,featured,intl,periodo,inscricoes,link,cronograma,publico,ordem) values (
  'Curso Nacional Nível 1', 'soon', 'Online', 30, 'A definir', 'Formação fundamental para novos treinadores de triathlon. Conteúdo alinhado às diretrizes da World Triathlon e adaptado à realidade brasileira.', true, false, 'A definir', 'A definir', null, null, null, 0);
insert into ubt_courses (title,status,format,vagas,carga_horaria,descricao,featured,intl,periodo,inscricoes,link,cronograma,publico,ordem) values (
  'Curso Nacional Nível 2', 'sold', 'Online', 30, 'A definir', 'Continuidade da formação para treinadores que já concluíram o Nível 1. 1ª turma encerrada com todas as vagas preenchidas.', true, false, 'A definir', 'Encerradas', null, null, null, 1);
insert into ubt_courses (title,status,format,vagas,carga_horaria,descricao,featured,intl,periodo,inscricoes,link,cronograma,publico,ordem) values (
  'World Triathlon Level 1 Online', 'sold', '100% Online', 20, null, 'Certificação internacional da World Triathlon na modalidade 100% online. Reconhecida em mais de 130 países.', true, true, '03/08/2026 a 09/2026', '08/07 a 15/07/2026', 'https://www.ticketsports.com.br/e/CERTIFICA%C3%87%C3%83O%20INTERNACIONAL%20DE%20TREINADORES%20WORLD%20TRIATHLON%20-%20N%C3%8DVEL%201%20(ONLINE)-87367', '{"inscricoes":"De 08/07/2026 (09h) a 15/07/2026 — ou enquanto durarem as vagas","vagas":"20 vagas","horarios":["Encontros síncronos de 60 min: 18h30 às 19h30 (horário de Brasília)","Encontros síncronos de 90 min: 18h30 às 20h00 (horário de Brasília)"],"encontros":[{"sem":"Welcome Meeting","data":"03/08/2026 (seg) · 60 min"},{"sem":"Semana 1","data":"12/08/2026 (qua) · 60 min"},{"sem":"Semana 2","data":"19/08/2026 (qua) · 60 min"},{"sem":"Semana 3","data":"26/08/2026 (qua) · 60 min"},{"sem":"Semana 4","data":"02/09/2026 (qua) · 60 min"},{"sem":"Semana 5","data":"09/09/2026 (qua) · 90 min • 10/09/2026 (qui) · 60 min"},{"sem":"Semana 6","data":"16/09/2026 (qua) · 90 min • 17/09/2026 (qui) · 60 min"},{"sem":"Semana 7","data":"Avaliações e reuniões individuais (20 a 30 min)"},{"sem":"Semana 8","data":"Avaliações e reuniões individuais (20 a 30 min)"},{"sem":"Semana 9","data":"Avaliações e reuniões individuais (20 a 30 min)"}]}'::jsonb, null, 2);
insert into ubt_courses (title,status,format,vagas,carga_horaria,descricao,featured,intl,periodo,inscricoes,link,cronograma,publico,ordem) values (
  'World Triathlon Level 1 Híbrido', 'open', 'Online + Presencial', 20, null, 'Certificação internacional com módulo presencial intensivo. Experiência prática supervisionada por facilitadores credenciados.', false, true, '13/10 a 29/11/2026', '23/09 a 30/09/2026', 'https://www.ticketsports.com.br/e/CERTIFICA%C3%87%C3%83O%20INTERNACIONAL%20DE%20TREINADORES%20WORLD%20TRIATHLON%20-%20N%C3%8DVEL%201%20(H%C3%8DBRIDO)-87467', '{"inscricoes":"De 23/09/2026 (09h) a 30/09/2026 — ou enquanto durarem as vagas","vagas":"20 vagas","horarios":["Encontros síncronos de 45 min: 18h30 às 19h15 (horário de Brasília)","Encontros síncronos de 60 min: 18h30 às 19h30 (horário de Brasília)"],"encontros":[{"sem":"Welcome Meeting","data":"13/10/2026 (seg) · 60 min"},{"sem":"Semana 1","data":"14/10/2026 (qua) · 60 min"},{"sem":"Semana 2","data":"19/10/2026 (seg) · 45 min • 22/10/2026 (qui) · 60 min"},{"sem":"Semana 3","data":"26/10/2026 (seg) · 45 min • 28/10/2026 (qua) · 60 min"},{"sem":"Semana 4","data":"02/11/2026 (seg) · 45 min • 04/11/2026 (qua) · 60 min"},{"sem":"Semana 5","data":"09/11/2026 (seg) · 45 min • 11/11/2026 (qua) · 60 min"}],"presencial":{"titulo":"Etapa Presencial · Rio de Janeiro (local a definir)","datas":["27/11/2026 (sexta-feira)","28/11/2026 (sábado)","29/11/2026 (domingo)"]}}'::jsonb, null, 3);
insert into ubt_courses (title,status,format,vagas,carga_horaria,descricao,featured,intl,periodo,inscricoes,link,cronograma,publico,ordem) values (
  'Introdução ao Triathlon', 'soon', 'Online', null, null, 'Curso introdutório para conhecer a modalidade, sua estrutura, regras, oportunidades profissionais e modelo de desenvolvimento esportivo da CBTri. Indicado para atletas, pais, estudantes, profissionais da saúde, gestores, oficiais técnicos e comunidade do triathlon.', false, false, 'A definir', 'A definir', null, null, ARRAY['Atletas','Pais','Estudantes','Profissionais da saúde','Gestores','Oficiais técnicos','Comunidade do triathlon']::text[], 4);

-- ---------- CALENDÁRIO ----------
insert into ubt_calendar (curso,periodo,inscricoes,vagas,formato,status,ordem) values (
  'CBTri Nível 1 — Turma 1', '27/02/2026 a 07/03/2026', '02/01/2026 a 03/02/2026', '30/30', 'Online', 'done', 0);
insert into ubt_calendar (curso,periodo,inscricoes,vagas,formato,status,ordem) values (
  'Curso Nacional Nível 1', 'A definir', 'A definir', '30', 'Online', 'soon', 1);
insert into ubt_calendar (curso,periodo,inscricoes,vagas,formato,status,ordem) values (
  'Curso Nacional Nível 2 — 1ª Turma', '2026', 'Encerradas', '30/30', 'Online', 'sold', 2);
insert into ubt_calendar (curso,periodo,inscricoes,vagas,formato,status,ordem) values (
  'World Triathlon Level 1 Online', '03/08 a 09/2026', '08/07 a 15/07/2026', '20/20', '100% Online', 'sold', 3);
insert into ubt_calendar (curso,periodo,inscricoes,vagas,formato,status,ordem) values (
  'World Triathlon Level 1 Híbrido', '13/10 a 29/11/2026', '23/09 a 30/09/2026', '20', 'Online + Presencial', 'open', 4);

-- ---------- CORPO DOCENTE ----------
insert into ubt_faculty (name,role,initials,badge,formacao,cert,experiencia,specs,link,photo_url,guest,ordem) values (
  'Dra. Elinai Freitas Schutz', 'Diretora Técnica CBTri', 'ES', 'WORLD TRIATHLON FACILITATOR', ARRAY['Doutora em Ciências do Movimento Humano','Mestre em Ciências do Movimento Humano','Bacharel e Licenciada em Educação Física (UDESC)']::text[], ARRAY['World Triathlon Level 2 Coach','CAMTRI Level 3 Coach','Coach Developer COB']::text[], ARRAY['Diretora Técnica da CBTri','Facilitadora World Triathlon','Mentora de treinadoras do Programa MIRA/COB','Comissão de Mulheres da Americas Triathlon','Mais de 20 anos no treinamento esportivo e formação de treinadores']::text[], ARRAY['Desenvolvimento de atletas','Formação de treinadores','Triathlon de base','Planejamento esportivo','Gestão técnica']::text[], 'http://lattes.cnpq.br/3263303501266158', 'faculty/dra-elinai-freitas-schutz.jpg', false, 0);
insert into ubt_faculty (name,role,initials,badge,formacao,cert,experiencia,specs,link,photo_url,guest,ordem) values (
  'Prof. Rogério Scheibe', 'Facilitador CBTri e World Triathlon', 'RS', 'WORLD TRIATHLON FACILITATOR', ARRAY['Mestre em Fisiologia do Exercício (UFPR)','Doutorando em andamento','Educação Física','Ciências Biológicas']::text[], ARRAY['Facilitador World Triathlon','Facilitador CBTri']::text[], ARRAY['Head Coach — Federação de Triathlon do Kuwait (2020–2022)','Especialista em desenvolvimento de treinadores','Pesquisador em desempenho humano','Autor de estudos sobre análise de performance no triathlon']::text[], ARRAY['Fisiologia aplicada','Treinamento esportivo','Desenvolvimento de atletas','Performance no triathlon','Educação continuada de treinadores']::text[], 'http://lattes.cnpq.br/0939644820659104', 'faculty/prof-rogerio-scheibe.jpg', false, 1);
insert into ubt_faculty (name,role,initials,badge,formacao,cert,experiencia,specs,link,photo_url,guest,ordem) values (
  'Facilitadores Convidados', 'Especialistas Nacionais e Internacionais', '★', 'GUEST EXPERTS', '{}', '{}', ARRAY['Profissionais nacionais e internacionais convidados para módulos específicos, webinars, clínicas e cursos avançados.']::text[], '{}', null, null, true, 2);

-- >>>>> 003 — STORAGE <<<<<
-- ============================================================
-- Universidade BT — Políticas de Storage (Fase 2)
-- Leitura pública das fotos já vem do bucket "ubt" ser público.
-- Aqui liberamos ESCRITA (upload/atualizar/remover) apenas para
-- usuários autenticados (staff logado no admin).
-- Rode após criar o bucket "ubt".
-- ============================================================

create policy "ubt_storage_authenticated_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'ubt');

create policy "ubt_storage_authenticated_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'ubt') with check (bucket_id = 'ubt');

create policy "ubt_storage_authenticated_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'ubt');
