-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Completa o card do Kaique Ferreira (foto + currículo).
-- Antes: suba a foto no Storage → bucket ubt → pasta facilitadores → kaique-ferreira.jpg
-- (este UPDATE já inclui a foto; substitui o update de foto anterior)
-- ============================================================

update ubt_faculty set
  role        = 'Professor de Paratriathlon — Escola Paralímpica de Esportes (CPB)',
  photo_url   = 'facilitadores/kaique-ferreira.jpg',
  formacao    = ARRAY[
    'Bacharel em Educação Física — Universidade São Judas Tadeu',
    'Pós-graduação em Atividade Física e Saúde para Grupos Especiais — USCS'
  ]::text[],
  cert        = ARRAY['Técnico Nível I de Triathlon — habilitações em Triathlon, Paratriathlon e Natação']::text[],
  experiencia = ARRAY[
    'Professor de Paratriathlon na Escola Paralímpica de Esportes do Comitê Paralímpico Brasileiro (desde 2022)',
    'Professor de Atividades Funcionais e Defesa Pessoal na Secretaria Municipal da Pessoa com Deficiência (desde 2025)',
    'Convocado pela Seleção Brasileira de Paratriathlon; atuou como Handler do atleta Welisson no Pan-Americano de Paratriathlon (Antofagasta, Chile)',
    'Como treinador: Campeão Paulista de Paratriathlon 2025 e Vice-Campeão Brasileiro 2024 (Marcelo Gonçalves da Silva, PTS5)',
    '3º lugar no Campeonato Paulista e no Brasileiro de Paratriathlon 2025 (Welisson José Damasceno, PTWC) — ambos convocados ao Pan-Americano de Antofagasta'
  ]::text[],
  specs       = ARRAY['Triathlon','Paratriathlon','Natação','Paranatação','Esporte para PcD','TEA','Síndrome de Down','Educação Antidoping']::text[]
where name = 'Kaique Ferreira';
