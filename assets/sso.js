/*
 * Login único: "Entrar com a conta Brasil Triathlon".
 *
 * A Plataforma Brasil Triathlon é o provedor de identidade (Supabase OAuth 2.1
 * do projeto da plataforma). O Academy é cliente PÚBLICO: fluxo authorization
 * code + PKCE, sem segredo no navegador. Contrato completo no repositório da
 * plataforma: docs/modulo-treinadores/SSO-ACADEMY.md.
 *
 * Decisão de segurança: os tokens NÃO ficam guardados. O access token da
 * plataforma vale como sessão do usuário lá; guardá-lo aqui (site estático)
 * daria a qualquer script da página acesso à conta da pessoa na plataforma.
 * O retorno usa o token UMA vez (rota /eu), guarda só o resumo de quem é
 * (nome, e-mail, id do treinador, certificações) e descarta o token.
 *
 * Consequência: a sessão do Academy é só de exibição. Nada que exija prova de
 * identidade no servidor (matrícula, pagamento) pode confiar neste resumo —
 * isso terá de passar por uma Edge Function que valide o token na hora.
 */
(function () {
  var CFG = {
    CLIENT_ID: "5890a36a-2101-40bd-8674-54ee84f78d1c", // público (cliente PKCE)
    AUTORIZAR: "https://pxsrbyhsqpkcyxpermhp.supabase.co/auth/v1/oauth/authorize",
    TOKEN: "https://pxsrbyhsqpkcyxpermhp.supabase.co/auth/v1/oauth/token",
    EU: "https://plataforma.triathlonbrasil.org.br/api/integracao/academy/v1/eu",
    PLATAFORMA: "https://plataforma.triathlonbrasil.org.br",
    CHAVE_SESSAO: "ubt_sso_sessao",
    CHAVE_PEDIDO: "ubt_sso_pedido",
    HORAS: 12,
  };

  function b64url(bytes) {
    var s = "";
    for (var i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
    return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }
  function aleatorio(n) { return b64url(crypto.getRandomValues(new Uint8Array(n))); }
  function redirectUri() { return location.origin + "/sso/retorno"; }

  // Só volta para página do próprio Academy (nada de redirecionar para fora).
  function voltarSeguro(v) {
    return typeof v === "string" && /^\/(?!\/)/.test(v) && v.indexOf("/sso/") !== 0 ? v : "/minha-area";
  }

  async function entrar(voltar) {
    var verifier = aleatorio(32);
    var digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier));
    var state = aleatorio(16);
    sessionStorage.setItem(CFG.CHAVE_PEDIDO, JSON.stringify({
      verifier: verifier, state: state, voltar: voltarSeguro(voltar || location.pathname + location.search),
    }));
    var u = new URL(CFG.AUTORIZAR);
    u.search = new URLSearchParams({
      response_type: "code", client_id: CFG.CLIENT_ID, redirect_uri: redirectUri(),
      scope: "openid email profile", state: state,
      code_challenge: b64url(new Uint8Array(digest)), code_challenge_method: "S256",
    }).toString();
    location.href = u.href;
  }

  // Chamado por /sso/retorno. Devolve o caminho para onde ir, ou lança erro com mensagem amigável.
  async function concluir(params) {
    var erro = params.get("error");
    if (erro) throw new Error(erro === "access_denied" ? "Você não autorizou o acesso." : "A plataforma recusou o login (" + erro + ").");
    var pedido = null;
    try { pedido = JSON.parse(sessionStorage.getItem(CFG.CHAVE_PEDIDO) || "null"); } catch (e) {}
    sessionStorage.removeItem(CFG.CHAVE_PEDIDO);
    if (!pedido || !params.get("code")) throw new Error("O login expirou ou foi aberto em outra aba. Tente de novo.");
    if (params.get("state") !== pedido.state) throw new Error("O retorno do login não confere. Tente de novo.");

    var r = await fetch(CFG.TOKEN, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code", code: params.get("code"), client_id: CFG.CLIENT_ID,
        redirect_uri: redirectUri(), code_verifier: pedido.verifier,
      }).toString(),
    });
    var tok = await r.json().catch(function () { return {}; });
    if (!r.ok || !tok.access_token) throw new Error("Não foi possível concluir o login. Tente de novo.");

    var e = await fetch(CFG.EU, { headers: { Authorization: "Bearer " + tok.access_token } });
    var eu = await e.json().catch(function () { return {}; });
    tok = null; // o token não sai daqui
    if (!e.ok || !eu.conta) throw new Error("Não foi possível ler os dados da sua conta. Tente de novo.");

    var t = eu.treinador;
    localStorage.setItem(CFG.CHAVE_SESSAO, JSON.stringify({
      conta_id: eu.conta.id,
      email: eu.conta.email,
      nome: (t && t.nome) || eu.conta.nome || eu.conta.email,
      treinador: t ? { id: t.id, nome: t.nome, foto_url: t.foto_url, cidade: t.cidade, uf: t.uf, ativo: t.ativo, equipes: t.equipes || [] } : null,
      certificacoes: eu.certificacoes, // null = Academy indisponível na hora
      expira_em: Date.now() + CFG.HORAS * 3600 * 1000,
    }));
    return voltarSeguro(pedido.voltar);
  }

  function sessao() {
    try {
      var s = JSON.parse(localStorage.getItem(CFG.CHAVE_SESSAO) || "null");
      if (s && s.expira_em > Date.now()) return s;
    } catch (e) {}
    try { localStorage.removeItem(CFG.CHAVE_SESSAO); } catch (e) {}
    return null;
  }

  function sair(destino) {
    try { localStorage.removeItem(CFG.CHAVE_SESSAO); } catch (e) {}
    location.href = destino || "/";
  }

  function esc(v) {
    return String(v == null ? "" : v).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function primeiroNome(n) {
    var p = String(n || "").trim().split(/\s+/)[0] || "";
    return p.charAt(0).toUpperCase() + p.slice(1).toLowerCase();
  }

  // Preenche o espaço [data-sso] da barra superior: "Entrar" ou "Olá, Fulano".
  function montarBotao() {
    var alvo = document.querySelector("[data-sso]");
    if (!alvo) return;
    var s = sessao();
    if (s) {
      alvo.innerHTML = '<a class="btn-top acesso sso" href="/minha-area" title="Minha área no Academy" aria-label="Minha área">' +
        '<span aria-hidden="true">👤</span><span class="rotulo"> ' + esc(primeiroNome(s.nome)) + "</span></a>";
    } else {
      alvo.innerHTML = '<button type="button" class="btn-top acesso sso" title="Entrar com a conta Brasil Triathlon" aria-label="Entrar">' +
        '<span aria-hidden="true">🔑</span><span class="rotulo"> Entrar</span></button>';
      alvo.querySelector("button").addEventListener("click", function () { entrar(); });
    }
  }

  window.UBT_SSO = { entrar: entrar, concluir: concluir, sessao: sessao, sair: sair, esc: esc, primeiroNome: primeiroNome, CFG: CFG };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", montarBotao);
  else montarBotao();
})();
