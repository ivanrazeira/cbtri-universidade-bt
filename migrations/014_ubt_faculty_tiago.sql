-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Completa o card do Tiago Gorgatti (foto, função, formação, experiência).
-- Antes: suba a foto no Storage → bucket ubt → pasta facilitadores → tiago-gorgatti.jpg
-- ============================================================

update ubt_faculty set
  role        = 'Coordenador Nacional de Para Triathlon',
  photo_url   = 'facilitadores/tiago-gorgatti.jpg',
  formacao    = ARRAY[
    'Profissional de Educação Física — CREF 010190-G/SP',
    'Especialista em Fisiologia, Biomecânica, Treinamento e Reabilitação — IOT da Faculdade de Medicina da USP'
  ]::text[],
  cert        = '{}',
  experiencia = ARRAY[
    'Coordenador Nacional de Para Triathlon',
    'Coordenador Técnico do Projeto Águas Abertas – CIEDEF (apoio da Emenda Parlamentar da Senadora Mara Gabrilli)',
    'Coordenador Técnico no Instituto Entre Rodas',
    'Diretor técnico do Selo PARATODOS',
    'Ex-técnico de Triathlon Paralímpico do Corinthians e das Seleções Paralímpicas de Triathlon (Rio 2016) e de Esporte de Neve (Sochi 2014)',
    'Fundador da Associação Esporte Atitude; coordenou esportes na Associação Desportiva para Deficientes e no Instituto Mara Gabrilli',
    'Títulos de seus atletas: 3x Copa do Mundo, 5x Parapan e 6x Brasileiro de Para Triathlon; 9x Brasileiro de Paraciclismo; 2x Maratona de Nova York'
  ]::text[],
  specs       = ARRAY['Para Triathlon','Paraciclismo','Fisiologia','Biomecânica','Reabilitação']::text[]
where name = 'Tiago Gorgatti';
