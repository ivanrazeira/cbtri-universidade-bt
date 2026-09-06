-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Adiciona Rodrigo Milazzo como Facilitador Convidado no corpo docente.
-- (Sem foto por enquanto — renderiza com as iniciais "RM". Para incluir foto:
--  suba em Storage → bucket ubt → pasta facilitadores → rodrigo-milazzo.jpg e
--  faça: update ubt_faculty set photo_url='facilitadores/rodrigo-milazzo.jpg'
--        where name='Rodrigo Milazzo';)
-- Idempotente: não duplica se já existir.
-- ============================================================

insert into ubt_faculty (name, role, initials, badge, formacao, cert, experiencia, specs, link, guest, ordem, ativo)
select
  'Rodrigo Milazzo',
  'Treinador e gestor de alto rendimento no triathlon',
  'RM',
  'FACILITADOR CONVIDADO',
  ARRAY[
    'Profissional de Educação Física — CREF 03855-G/RJ',
    'Bacharelado/Licenciatura em Educação Física (2000) — Universidade Estácio de Sá',
    'Mestre pela Loughborough University, Reino Unido',
    'Certificação em Gestão Avançada do Esporte (2014) — Comitê Olímpico Internacional',
    'Especialização em Ciências Aplicadas ao Esporte de Elite (2024) — Sports Academy Lausanne'
  ]::text[],
  ARRAY[
    'Treinador Nacional (2005) — Confederação Brasileira de Triathlon',
    'High Performance Coach (2008) — Federação Internacional de Triathlon'
  ]::text[],
  ARRAY[
    'Coordenador de Desenvolvimento do Esporte (2009–2024) — CBTri',
    'Gerente Técnico Nacional e de Alto Rendimento (2017–2024) — CBTri',
    'Treinador Nacional de Alto Rendimento e Desenvolvimento de Atletas (2011–2024) — CBTri',
    'Membro do Comitê de Treinadores Nacionais (2020) — Federação Internacional de Triathlon',
    'Facilitador e mentor em programas de formação de treinadores (CBTri e Federação Internacional de Triathlon)'
  ]::text[],
  ARRAY['Alto rendimento','Desenvolvimento de atletas','Gestão esportiva','Formação de treinadores','Treinamento esportivo']::text[],
  null,
  true,
  coalesce((select max(ordem) from ubt_faculty), 0) + 1,  -- entra por último (depois dos demais convidados)
  true
where not exists (select 1 from ubt_faculty where name = 'Rodrigo Milazzo');
