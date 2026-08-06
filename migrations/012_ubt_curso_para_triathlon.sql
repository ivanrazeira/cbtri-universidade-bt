-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO (Universidade): edbyrcyvlowcylljebmq
--    NÃO rode no da plataforma (pxsrbyhsqpkcyxpermhp).
--    Confira: a URL do SQL Editor deve conter "edbyrcyvlowcylljebmq".
--
-- Adiciona o curso "Nível 1 Nacional — Habilitação em Para Triathlon".
-- Link de inscrição fica NULL (pendente) — atualize quando tiver a URL.
-- ============================================================

insert into ubt_courses
  (title, categoria, status, format, vagas, carga_horaria, descricao, featured, intl, periodo, inscricoes, link, cronograma, ordem, ativo)
values (
  'Nível 1 Nacional — Habilitação em Para Triathlon',
  'certificacao_bt',
  'open',
  'Híbrido',
  null,
  '6h',
  'Habilitação em Para Triathlon dentro do Nível 1 Nacional — curso híbrido e gratuito, em parceria com a educação paralímpica do CPB. Voltado a profissionais de Educação Física com CREF ativo e a estudantes de Educação Física do 7º e 8º semestre que já concluíram os cursos Movimento Paralímpico – Fundamentos Básicos do Esporte e Iniciação ao Para Triathlon.',
  true,
  false,
  '23 e 24/09/2026',
  'Até 06/09/2026 · Gratuito',
  null,
  '{
    "inscricoes": "Até 06/09/2026 — gratuito, vagas limitadas",
    "vagas": "Vagas limitadas (gratuito)",
    "horarios": [
      "Curso híbrido · carga horária de 6h · em parceria com a educação paralímpica do CPB",
      "Pré-requisito: ter concluído Movimento Paralímpico – Fundamentos Básicos do Esporte e Iniciação ao Para Triathlon",
      "Público: profissionais de Educação Física com CREF ativo e estudantes de Educação Física do 7º e 8º semestre",
      "Comprovação técnica: após a inscrição é obrigatório anexar o registro no CREF vigente OU comprovante de que cursa o 7º/8º semestre de Educação Física — sem o envio, a inscrição é cancelada em 24 horas",
      "Realização: CPB, Secretaria de Estado de Esporte e Lazer, Goiás Social, Paradesporto e Centro de Referência Paralímpica Brasileiro de Goiás · Apoio: UFU · Patrocínio: Loterias Caixa, Caixa e Governo do Brasil"
    ],
    "encontros": [
      {"sem": "23/09 (qua) · 10h–11h", "data": "Introdução e Aspectos Pedagógicos — Ivan Razeira, Tiago Gorgatti, Rogério Scheibe Filho e Elinai Freitas"},
      {"sem": "23/09 (qua) · 11h–12h", "data": "Modelo de Desenvolvimento de Atletas de Triathlon no Brasil — Rogério Scheibe Filho e Elinai Freitas"},
      {"sem": "23/09 (qua) · 12h–13h", "data": "Natação no Para Triathlon — Elinai Freitas, Rogério Scheibe Filho, Tiago Gorgatti e Ivan Razeira"},
      {"sem": "24/09 (qui) · 10h–11h", "data": "Ciclismo no Para Triathlon — Elinai Freitas, Rogério Scheibe Filho, Tiago Gorgatti e Ivan Razeira"},
      {"sem": "24/09 (qui) · 11h–12h", "data": "Corrida no Para Triathlon — Elinai Freitas, Rogério Scheibe Filho, Tiago Gorgatti e Ivan Razeira"},
      {"sem": "24/09 (qui) · 12h–13h", "data": "Iniciação Esportiva no Para Triathlon — Kaique Ferreira e Tiago Gorgatti"}
    ]
  }'::jsonb,
  6,
  true
);
