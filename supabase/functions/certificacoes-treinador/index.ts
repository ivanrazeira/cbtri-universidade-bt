// Edge Function do ACADEMY (projeto edbyrcyvlowcylljebmq):
// certificações de treinadores para a Plataforma Brasil Triathlon.
//
// POST { emails: string[] }  →  { certificacoes: [{ email, nivel, turma, ano }] }
//
// - Só responde a quem manda o cabeçalho `x-plataforma-token` igual ao segredo
//   PLATAFORMA_CERTIFICACOES_TOKEN (o mesmo valor guardado no Worker da
//   plataforma). Comparação em tempo constante.
// - Devolve só nível, turma e ano. Nome e CREF não saem: a plataforma já tem
//   o nome do treinador e não precisa do resto.
// - O Academy é a fonte da verdade das certificações; a plataforma só exibe.
//
// Publicar no painel: Edge Functions → Deploy a new function → nome
// "certificacoes-treinador", colar este arquivo, e DESLIGAR "Verify JWT"
// (a autenticação é o token acima). Segredo em Edge Functions → Secrets.
import { createClient } from "jsr:@supabase/supabase-js@2";

function iguais(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a), y = new TextEncoder().encode(b);
  if (x.length !== y.length || x.length === 0) return false;
  let d = 0;
  for (let i = 0; i < x.length; i++) d |= x[i] ^ y[i];
  return d === 0;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Método não permitido", { status: 405 });
  const segredo = Deno.env.get("PLATAFORMA_CERTIFICACOES_TOKEN") ?? "";
  if (segredo.length < 32 || !iguais(req.headers.get("x-plataforma-token") ?? "", segredo)) {
    return Response.json({ error: "Não autorizado." }, { status: 401 });
  }

  const body = await req.json().catch(() => ({}));
  const emails = [...new Set((Array.isArray(body?.emails) ? body.emails : [])
    .filter((e: unknown): e is string => typeof e === "string")
    .map((e: string) => e.trim().toLowerCase())
    .filter((e: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e)))].slice(0, 500);
  if (!emails.length) return Response.json({ certificacoes: [] });

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data, error } = await sb.from("ubt_certificacoes")
    .select("email, nivel, turma, ano").in("email", emails).order("ano").order("nivel");
  if (error) return Response.json({ error: "Erro ao consultar." }, { status: 500 });
  return Response.json({ certificacoes: data ?? [] });
});
