-- ============================================================
-- ⚠️ RODAR NO PROJETO ISOLADO: edbyrcyvlowcylljebmq (não a plataforma)
-- Adiciona Tiago Gorgatti e Kaique Ferreira ao corpo docente como
-- facilitadores convidados (cards mínimos — foto/bio a completar depois).
-- ============================================================

insert into ubt_faculty (name, role, initials, badge, formacao, cert, experiencia, specs, link, photo_url, guest, ordem) values
(
  'Tiago Gorgatti', 'Facilitador – Para Triathlon', 'TG', 'FACILITADOR CONVIDADO',
  '{}', '{}', ARRAY['Facilitador do curso Nível 1 Nacional – Habilitação em Para Triathlon (CBTri / CPB)']::text[], '{}',
  null, null, true, 5
),
(
  'Kaique Ferreira', 'Facilitador – Para Triathlon', 'KF', 'FACILITADOR CONVIDADO',
  '{}', '{}', ARRAY['Facilitador do curso Nível 1 Nacional – Habilitação em Para Triathlon (CBTri / CPB)']::text[], '{}',
  null, null, true, 6
);
