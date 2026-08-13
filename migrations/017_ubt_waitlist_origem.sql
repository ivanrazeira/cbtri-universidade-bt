-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq
-- Adiciona o campo "origem" na lista de espera para distinguir a fonte
-- do lead (ex.: 'Live Ciência da Carga 18/08', 'Card do site', etc.).
-- ============================================================

alter table ubt_waitlist add column if not exists origem text;
