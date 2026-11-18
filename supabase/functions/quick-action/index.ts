// ============================================================
// Universidade BT — Edge Function: gestão de acessos (admin)
// Cria/lista/remove logins e mantém a lista ubt_admins.
// Usa a SERVICE_ROLE (secreta, injetada pelo Supabase) — nunca vai ao navegador.
// Só executa se o chamador for um admin já presente em ubt_admins.
// Publicada como "quick-action" (o cliente chama /functions/v1/quick-action).
// Deploy pelo painel (colar este código na função quick-action) ou por terminal:
//   npx supabase functions deploy quick-action --project-ref edbyrcyvlowcylljebmq
// Secrets necessários: RESEND_API_KEY e RESEND_FROM (para a ação "notify").
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (obj: unknown, status = 200) =>
  new Response(JSON.stringify(obj), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

    // 1) identifica o chamador pelo JWT da sessão
    const token = (req.headers.get("Authorization") || "").replace("Bearer ", "");
    const { data: u, error: uErr } = await admin.auth.getUser(token);
    if (uErr || !u?.user) return json({ error: "Não autenticado" }, 401);
    const caller = u.user;

    // 2) confere se o chamador é admin (está na lista)
    const { data: adm } = await admin.from("ubt_admins").select("user_id").eq("user_id", caller.id).maybeSingle();
    if (!adm) return json({ error: "Sem permissão para gerenciar acessos" }, 403);

    const body = await req.json().catch(() => ({}));
    const action = body.action;

    if (action === "list") {
      const { data, error } = await admin.from("ubt_admins").select("*").order("created_at");
      if (error) throw error;
      return json({ data });
    }

    if (action === "create") {
      const { email, password, nome, role } = body;
      if (!email || !password) return json({ error: "E-mail e senha são obrigatórios" }, 400);
      if (String(password).length < 8) return json({ error: "A senha deve ter ao menos 8 caracteres" }, 400);
      const { data: created, error: cErr } = await admin.auth.admin.createUser({
        email, password, email_confirm: true,
      });
      if (cErr) return json({ error: cErr.message }, 400);
      const { error: iErr } = await admin.from("ubt_admins").insert({
        user_id: created.user.id, email, nome: nome || null, role: role || "admin",
      });
      if (iErr) { await admin.auth.admin.deleteUser(created.user.id); return json({ error: iErr.message }, 400); }
      return json({ ok: true, user_id: created.user.id });
    }

    if (action === "reset_password") {
      const { user_id, password } = body;
      if (!user_id || !password) return json({ error: "Dados obrigatórios" }, 400);
      if (String(password).length < 8) return json({ error: "A senha deve ter ao menos 8 caracteres" }, 400);
      const { error } = await admin.auth.admin.updateUserById(user_id, { password });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    if (action === "delete") {
      const { user_id } = body;
      if (!user_id) return json({ error: "user_id obrigatório" }, 400);
      if (user_id === caller.id) return json({ error: "Você não pode remover o próprio acesso" }, 400);
      await admin.from("ubt_admins").delete().eq("user_id", user_id);
      await admin.auth.admin.deleteUser(user_id);
      return json({ ok: true });
    }

    // Cria login ESCOPADO de facilitador: conta de auth SEM entrar em ubt_admins.
    // O acesso dele é limitado por RLS às ações onde o e-mail é parte (migration 027).
    if (action === "create_facilitador") {
      const { email, password } = body;
      if (!email || !password) return json({ error: "E-mail e senha são obrigatórios" }, 400);
      if (String(password).length < 8) return json({ error: "A senha deve ter ao menos 8 caracteres" }, 400);
      const { data: created, error } = await admin.auth.admin.createUser({ email, password, email_confirm: true });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true, user_id: created.user.id });
    }

    // Redefine a senha de um facilitador pelo e-mail (ele não está em ubt_admins).
    if (action === "reset_facilitador") {
      const { email, password } = body;
      if (!email || !password) return json({ error: "E-mail e senha são obrigatórios" }, 400);
      if (String(password).length < 8) return json({ error: "A senha deve ter ao menos 8 caracteres" }, 400);
      let user: any = null, page = 1;
      while (page <= 20) {
        const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
        if (error) return json({ error: error.message }, 400);
        user = (data.users || []).find((u: any) => (u.email || "").toLowerCase() === String(email).toLowerCase());
        if (user || (data.users || []).length < 1000) break;
        page++;
      }
      if (!user) return json({ error: "Login não encontrado para " + email }, 404);
      const { error } = await admin.auth.admin.updateUserById(user.id, { password });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    // Emissão de certificados (participação em curso OU nível). Admin-only (já checado).
    // Foto congelada: reserva código (sequência atômica) + snapshot + hash. Idempotente.
    if (action === "emitir_certificados") {
      const base = String(body.base || "https://academy.triathlonbrasil.org.br").replace(/\/$/, "");
      const sha256 = async (s: string) => {
        const h = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
        return Array.from(new Uint8Array(h)).map((x) => x.toString(16).padStart(2, "0")).join("");
      };
      const emitirUm = async (rec: Record<string, unknown>, campos: Record<string, unknown>, ano: number) => {
        const { data: seq, error: seqErr } = await admin.rpc("ubt_proximo_cert_seq", { p_ano: ano });
        if (seqErr) throw seqErr;
        const codigo = `BTA-${ano}-${String(seq).padStart(6, "0")}`;
        const url_validacao = `${base}/validar?cod=${codigo}`;
        const hash = await sha256(`${codigo}|${rec.nome}|${JSON.stringify(campos)}`);
        const { error } = await admin.from("ubt_certificados").insert({
          ...rec, codigo, ano, sequencial: seq, campos, hash_conteudo: hash, url_validacao,
          emitido_por: caller.email || null,
        });
        if (error) throw error;
      };

      const assinaturas = Array.isArray(body.assinaturas) ? body.assinaturas : [];

      if (body.fonte === "participacao") {
        if (!body.acao_id) return json({ error: "acao_id obrigatório" }, 400);
        const { data: acao } = await admin.from("ubt_acoes").select("*").eq("id", body.acao_id).single();
        if (!acao) return json({ error: "Ação não encontrada" }, 404);
        const { data: inscritos } = await admin.from("ubt_acao_inscritos").select("*").eq("acao_id", body.acao_id);
        const pagos = (inscritos || []).filter((x: any) => String(x.status || "").toLowerCase() === "pago" && !x.cancelado && x.documento);
        const { data: jaTem } = await admin.from("ubt_certificados").select("documento").eq("acao_id", body.acao_id).eq("tipo", "participacao");
        const feitos = new Set((jaTem || []).map((x: any) => x.documento));
        const ano = body.data_conclusao ? parseInt(String(body.data_conclusao).slice(0, 4)) : new Date().getFullYear();
        let emitidos = 0, pulados = 0;
        const semDoc = (inscritos || []).filter((x: any) => String(x.status || "").toLowerCase() === "pago" && !x.cancelado && !x.documento).length;
        for (const p of pagos) {
          if (feitos.has(p.documento)) { pulados++; continue; }
          const campos = {
            tipo_texto: "de conclusão",
            categoria: body.categoria || "Curso livre",
            titulo: body.titulo || acao.titulo,
            subtitulo: body.subtitulo || null,
            carga: body.carga || acao.carga_horaria || null,
            periodo: body.periodo || null,
            modalidade: body.modalidade || acao.formato || null,
            assinaturas, base_legal: body.base_legal || null,
            programa: Array.isArray(body.programa) ? body.programa : [],
          };
          await emitirUm({ tipo: "participacao", acao_id: body.acao_id, nome: p.nome, documento: p.documento, email: p.email }, campos, ano);
          emitidos++;
        }
        return json({ ok: true, emitidos, ja_existiam: pulados, sem_documento: semDoc });
      }

      if (body.fonte === "nivel") {
        const NIVEL_NOME: Record<string, string> = {
          N1: "Treinador Nível 1", N2: "Treinador Nível 2",
          WT1: "World Triathlon Level 1", N1P: "Treinador Nível 1 — Habilitação em Paratriathlon",
        };
        let q = admin.from("ubt_certificacoes").select("*");
        if (Array.isArray(body.certificacao_ids) && body.certificacao_ids.length) q = q.in("id", body.certificacao_ids);
        if (body.nivel) q = q.eq("nivel", body.nivel);
        if (body.turma) q = q.eq("turma", body.turma);
        const { data: regs } = await q;
        const { data: jaTem } = await admin.from("ubt_certificados").select("certificacao_id").eq("tipo", "nivel");
        const feitos = new Set((jaTem || []).map((x: any) => x.certificacao_id));
        let emitidos = 0, pulados = 0;
        for (const r of (regs || [])) {
          if (feitos.has(r.id)) { pulados++; continue; }
          const campos = {
            tipo_texto: "de conclusão",
            categoria: "Formação de treinadores",
            categoria_frase: "curso de formação de treinadores",
            titulo: NIVEL_NOME[r.nivel] || r.nivel,
            subtitulo: null,
            periodo: `Turma ${r.turma} · ${r.ano}`,
            assinaturas,
          };
          await emitirUm({ tipo: "nivel", certificacao_id: r.id, nome: r.nome, email: r.email }, campos, r.ano);
          emitidos++;
        }
        return json({ ok: true, emitidos, ja_existiam: pulados });
      }

      return json({ error: "fonte inválida (use 'participacao' ou 'nivel')" }, 400);
    }

    // Revoga um certificado (mantém a linha; vira 'revogado').
    if (action === "revogar_certificado") {
      if (!body.codigo) return json({ error: "codigo obrigatório" }, 400);
      const { error } = await admin.from("ubt_certificados").update({
        situacao: "revogado", motivo_revogacao: body.motivo || null,
        revogado_em: new Date().toISOString(), revogado_por: caller.email || null,
      }).eq("codigo", body.codigo);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    // Envio de e-mail de aviso (tramitação) via Resend.
    // Requer os secrets RESEND_API_KEY e (recomendado) RESEND_FROM no projeto.
    if (action === "notify") {
      const { to, cc, subject, text, html } = body;
      if (!to || !subject) return json({ error: "to e subject são obrigatórios" }, 400);
      const RESEND_KEY = Deno.env.get("RESEND_API_KEY");
      if (!RESEND_KEY) return json({ error: "RESEND_API_KEY não configurado no projeto" }, 400);
      const FROM = Deno.env.get("RESEND_FROM") || "Brasil Triathlon Academy <onboarding@resend.dev>";
      const payload: Record<string, unknown> = { from: FROM, to: [to], subject, text: text || undefined, html: html || undefined };
      if (Array.isArray(cc) && cc.length) payload.cc = cc;
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { "Authorization": `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const jr = await r.json().catch(() => ({}));
      if (!r.ok) return json({ error: (jr as any)?.message || `Resend erro ${r.status}` }, 400);
      return json({ ok: true, id: (jr as any)?.id });
    }

    return json({ error: "Ação inválida" }, 400);
  } catch (e) {
    return json({ error: (e as Error)?.message || String(e) }, 500);
  }
});
