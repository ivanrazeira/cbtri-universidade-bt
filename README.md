# Universidade BT — Brasil Triathlon Academy

Site oficial de formação de treinadores da CBTri. `cursos.triathlonbrasil.org.br`.

Página estática (HTML/JS puro, **sem build**) que carrega o conteúdo — cursos, calendário
e corpo docente — do **Supabase**, com **fallback automático** para dados locais embutidos
(se o Supabase não estiver configurado ou fora do ar, a página funciona igual).

## Estrutura

```
index.html               Página única (público). Contém UBT_CONFIG (chaves) e o fallback local.
assets/faculty/          Fotos dos docentes (fonte) — devem ser enviadas ao Storage do Supabase.
migrations/
  001_ubt_schema.sql     Tabelas: ubt_courses, ubt_faculty, ubt_calendar, ubt_waitlist + RLS.
  002_ubt_seed.sql       Conteúdo atual, para popular o banco na primeira carga.
```

## Configuração (Fase 1 — fazer uma vez)

1. **Rodar as migrations** no SQL Editor do Supabase, na ordem:
   `001_ubt_schema.sql` → `002_ubt_seed.sql`.
2. **Storage**: criar um bucket **público** chamado `ubt` e enviar as fotos para a pasta
   `faculty/` mantendo os nomes: `dra-elinai-freitas-schutz.jpg` e `prof-rogerio-scheibe.jpg`
   (os mesmos referenciados no seed).
3. **Chaves**: em `index.html`, preencher `window.UBT_CONFIG` com a **Project URL** e a
   **anon public key** do projeto. (A anon key é pública por design; o acesso é limitado por RLS.)
4. Publicar. A página passa a ler do banco; os docentes carregam as fotos do Storage.

Enquanto `UBT_CONFIG` estiver vazio, a página usa o conteúdo local embutido (comportamento atual).

## Deploy (Cloudflare)

⚠️ **Nunca** use "Salvar como → Página completa" do navegador para publicar — isso corrompe o
UTF-8 (acentos/emojis viram `Ã§`, `ðŸ`) e injeta lixo de extensão. Publique **o arquivo-fonte**.

Recomendado: **Cloudflare Pages conectado a um repositório Git** — cada `git push` publica
automático, sem upload manual. Alternativa: upload direto do `index.html` no painel do Pages.

## Roadmap

- [x] **Fase 1** — banco + página lendo do Supabase (fallback local). *Aguardando: rodar migrations, bucket, chaves.*
- [ ] **Fase 2** — painel admin (Supabase Auth) para gerenciar cursos/calendário/docentes.
- [ ] **Fase 3** — lista de espera gravando no Supabase (aposenta o Google Apps Script).
- [ ] **Fase 4** — inscrições/matrículas + controle automático de vagas (`vagas_ocupadas`).
- [ ] **Fase 5** — área do aluno + emissão/validação de certificados.
