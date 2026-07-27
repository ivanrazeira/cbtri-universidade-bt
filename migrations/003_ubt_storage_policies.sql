-- ============================================================
-- Universidade BT — Políticas de Storage (Fase 2)
-- Leitura pública das fotos já vem do bucket "ubt" ser público.
-- Aqui liberamos ESCRITA (upload/atualizar/remover) apenas para
-- usuários autenticados (staff logado no admin).
-- Rode após criar o bucket "ubt".
-- ============================================================

create policy "ubt_storage_authenticated_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'ubt');

create policy "ubt_storage_authenticated_update"
  on storage.objects for update to authenticated
  using (bucket_id = 'ubt') with check (bucket_id = 'ubt');

create policy "ubt_storage_authenticated_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'ubt');
