-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq
-- Conteúdo programático do curso "Ciência da Carga Interna" (4 aulas).
-- ============================================================

update ubt_courses set cronograma = '{
  "conteudo": [
    {
      "titulo": "Aula 1. Ciência da carga interna",
      "descricao": "Carga externa vs. interna. Origem histórica (Banister, TRIMP). Taxonomia da carga — mecânica vs. metabólica, case Lionel Sanders. Panorama dos sinais das próximas aulas.",
      "objetivo": "Dar o vocabulário e a lógica que sustentam as aulas seguintes, antes de qualquer métrica."
    },
    {
      "titulo": "Aula 2. Fisiologia dos limiares",
      "descricao": "De onde vêm as zonas de treino. VO2máx, limiares ventilatórios e de lactato, potência e velocidade crítica, CSS. Teste de laboratório versus teste de campo.",
      "objetivo": "Se a zona está errada, todo o monitoramento vem errado."
    },
    {
      "titulo": "Aula 3. Como quantificar e ler ao longo do tempo",
      "descricao": "TRIMP, RPE de sessão, métricas do TrainingPeaks (TSS, IF, NP, CTL, ATL, TSB), desacoplamento, monotonia e strain. O que o ACWR mostra e o que não mostra.",
      "objetivo": "Transformar sessões isoladas em uma série histórica legível."
    },
    {
      "titulo": "Aula 4. Prontidão, fadiga e decisão",
      "descricao": "HRV, sono, questionários de bem-estar. Diferenciar fadiga normal de overreaching e overtraining. Painel semanal do treinador, estudos de caso com dados reais.",
      "objetivo": "Ensinar o treinador a olhar uma semana de dados e justificar, com base fisiológica, por que manteve, reduziu ou aumentou a carga."
    }
  ]
}'::jsonb
where title ilike 'Ciência da Carga%';
