-- ============================================================
-- Universidade BT — Facilitadores por curso
-- Adiciona a coluna facilitadores (JSONB) e preenche o curso
-- "Ciência da Carga Interna" com José Cruvinel Neto e Marcio Lazari.
-- As fotos devem estar no Storage: bucket ubt, pasta facilitadores/.
-- Rode no projeto isolado (edbyrcyvlowcylljebmq).
-- ============================================================

alter table ubt_courses add column if not exists facilitadores jsonb;

update ubt_courses set facilitadores = '[
  {
    "nome": "José Cruvinel Neto",
    "papel": "Médico do Esporte e Cirurgião do Trauma",
    "foto": "facilitadores/jose-cruvinel-neto.jpg",
    "lattes": "http://lattes.cnpq.br/2634800583311655",
    "bio": [
      "Médico do Esporte pelo Instituto Vita",
      "Médico Cirurgião do Trauma formado pela Unicamp",
      "Founder Cliff",
      "Mestre em Ciências da Saúde pelo IAMSPE",
      "Médico do Instituto de Ortopedia e Traumatologia do HCFMUSP",
      "Fellow do Colégio Americano de Cirurgiões",
      "Áreas de atuação: monitoramento de atletas, resgate de áreas remotas e utilização de ultrassom point of care",
      "Manager e médico da equipe Gen2Rise MTB profissional",
      "Médico do Esporte e Responsável Técnico na Oxia – São Paulo"
    ]
  },
  {
    "nome": "Marcio Lazari",
    "papel": "Professor e Especialista em Ciências do Esporte / Endurance",
    "foto": "facilitadores/marcio-lazari.jpg",
    "lattes": "https://lattes.cnpq.br/9620497526144188",
    "bio": [
      "Graduado em Educação Física – Unicamp; Especialização em Bioquímica do Exercício e Mestre em Ciências do Esporte – FEF/Unicamp",
      "Treinador, avaliador e personal trainer em esportes de endurance desde 2001",
      "Triathlon: ex-atleta e treinador com background em ciência e desempenho de curta e longa duração",
      "Assessoria esportiva para atletas profissionais e amadores em triathlon, ciclismo e corrida; campeão mundial de automobilismo – turismo elétrico (2020)",
      "Reconhecido por workshops e palestras para treinadores desde 2015, com mais de 700 profissionais atendidos",
      "Docente na pós-graduação em endurance – Instituto Valorize",
      "Analista de desempenho e Treinador na equipe Gen2Rise MTB",
      "Organizador do Simpósio Tech Bike 2025",
      "Head em Preparação Física na Oxia – centro para saúde, bem-estar e desempenho"
    ]
  }
]'::jsonb
where title ilike 'Ciência da Carga%';
