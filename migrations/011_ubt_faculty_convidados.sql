-- ============================================================
-- Universidade BT — Facilitadores convidados no corpo docente
-- Adiciona José Cruvinel Neto e Marcio Lazari em ubt_faculty (guest).
-- Reaproveita as fotos em Storage: facilitadores/*.jpg
-- Rode no projeto isolado.
-- ============================================================

insert into ubt_faculty (name, role, initials, badge, formacao, cert, experiencia, specs, link, photo_url, guest, ordem) values
(
  'José Cruvinel Neto', 'Médico do Esporte e Cirurgião do Trauma', 'JC', 'FACILITADOR CONVIDADO',
  '{}', '{}',
  ARRAY[
    'Médico do Esporte pelo Instituto Vita',
    'Médico Cirurgião do Trauma formado pela Unicamp',
    'Founder Cliff',
    'Mestre em Ciências da Saúde pelo IAMSPE',
    'Médico do Instituto de Ortopedia e Traumatologia do HCFMUSP',
    'Fellow do Colégio Americano de Cirurgiões',
    'Áreas de atuação: monitoramento de atletas, resgate de áreas remotas e utilização de ultrassom point of care',
    'Manager e médico da equipe Gen2Rise MTB profissional',
    'Médico do Esporte e Responsável Técnico na Oxia – São Paulo'
  ]::text[],
  '{}', 'http://lattes.cnpq.br/2634800583311655', 'facilitadores/jose-cruvinel-neto.jpg', true, 3
),
(
  'Marcio Lazari', 'Professor e Especialista em Ciências do Esporte / Endurance', 'ML', 'FACILITADOR CONVIDADO',
  '{}', '{}',
  ARRAY[
    'Graduado em Educação Física – Unicamp; Especialização em Bioquímica do Exercício e Mestre em Ciências do Esporte – FEF/Unicamp',
    'Treinador, avaliador e personal trainer em esportes de endurance desde 2001',
    'Triathlon: ex-atleta e treinador com background em ciência e desempenho de curta e longa duração',
    'Assessoria esportiva para atletas profissionais e amadores em triathlon, ciclismo e corrida; campeão mundial de automobilismo – turismo elétrico (2020)',
    'Reconhecido por workshops e palestras para treinadores desde 2015, com mais de 700 profissionais atendidos',
    'Docente na pós-graduação em endurance – Instituto Valorize',
    'Analista de desempenho e Treinador na equipe Gen2Rise MTB',
    'Organizador do Simpósio Tech Bike 2025',
    'Head em Preparação Física na Oxia – centro para saúde, bem-estar e desempenho'
  ]::text[],
  '{}', 'https://lattes.cnpq.br/9620497526144188', 'facilitadores/marcio-lazari.jpg', true, 4
);
