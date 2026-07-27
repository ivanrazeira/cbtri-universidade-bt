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
