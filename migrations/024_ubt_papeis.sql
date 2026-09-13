-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Atribuição de PAPÉIS funcionais para a segregação do fluxo (IN art. 14/15).
-- Enquanto um admin não tiver papéis, ele conduz TODO o fluxo (modo teste).
-- Vocabulário: coordenacao | direcao_tecnica | direcao_geral | administrativo | adm_financeiro | presidencia
-- Etapas → papel responsável:
--   proposicao→coordenacao · homologacao_docente/ateste→direcao_tecnica
--   aprovacao_plano/autorizacao→direcao_geral · inscricoes→administrativo
--   apuracao/execucao→adm_financeiro
-- Edite os e-mails abaixo e rode. Idempotente (sobrescreve os papéis do e-mail).
-- ============================================================

-- Direção Geral (aprova o plano e autoriza o pagamento)
update ubt_admins set papeis = array['direcao_geral']    where email = 'ivan.razeira@cbtri.org.br';

-- Preencha e descomente conforme a equipe:
-- update ubt_admins set papeis = array['coordenacao']     where email = 'coordenacao@cbtri.org.br';
-- update ubt_admins set papeis = array['direcao_tecnica'] where email = 'dt@cbtri.org.br';
-- update ubt_admins set papeis = array['administrativo']  where email = 'administrativo@cbtri.org.br';
-- update ubt_admins set papeis = array['adm_financeiro']  where email = 'financeiro@cbtri.org.br';
-- update ubt_admins set papeis = array['presidencia']     where email = 'presidencia@cbtri.org.br';

-- Conferir:
-- select email, papeis from ubt_admins order by email;
