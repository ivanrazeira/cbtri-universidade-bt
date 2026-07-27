// ============================================================
// Universidade BT — Edge Function: gestão de acessos (admin)
// Cria/lista/remove logins e mantém a lista ubt_admins.
// Usa a SERVICE_ROLE (secreta, injetada pelo Supabase) — nunca vai ao navegador.
// Só executa se o chamador for um admin já presente em ubt_admins.
// Deploy: Supabase Dashboard → Edge Functions → Deploy new function → nome "manage-users".
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

    return json({ error: "Ação inválida" }, 400);
  } catch (e) {
    return json({ error: (e as Error)?.message || String(e) }, 500);
  }
});
