-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Vincula a foto do Rodrigo Milazzo ao card.
-- ANTES: suba o arquivo no Storage → bucket "ubt" → pasta "facilitadores"
--        → nome exato "rodrigo-milazzo.jpg".
-- ============================================================

update ubt_faculty
   set photo_url = 'facilitadores/rodrigo-milazzo.jpg'
 where name = 'Rodrigo Milazzo';
