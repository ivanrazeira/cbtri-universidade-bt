-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- E-mail do facilitador/parte, para cópia no fluxo e aviso final de pagamento.
-- Depende da 021. Idempotente.
-- ============================================================

alter table ubt_acao_beneficiarios add column if not exists email text;

comment on column ubt_acao_beneficiarios.email is 'E-mail do facilitador/parte: recebe cópia dos avisos do fluxo e o aviso final de pagamento; assina o termo/recibo no PDF.';
