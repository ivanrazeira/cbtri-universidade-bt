-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Destinatário do aviso da próxima etapa (tramitação). Depende da 021. Idempotente.
-- ============================================================

alter table ubt_acao_eventos add column if not exists notificado_email text;   -- destinatário do aviso da próxima etapa
alter table ubt_acao_eventos add column if not exists notificado_nome  text;
alter table ubt_acao_eventos add column if not exists notificado_em    timestamptz; -- quando o aviso foi efetivamente enviado (null = ainda não)

comment on column ubt_acao_eventos.notificado_email is 'Pessoa designada para a próxima etapa do fluxo (recebe o pedido de aprovação).';
