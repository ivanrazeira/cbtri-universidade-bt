/* QR Code — codificador próprio, modo byte, correção M, versões 1–6.
 * Portado 1:1 do cbtri-platform/src/lib/qrcode.ts (validado contra segno + leitor do macOS).
 * Saída = SVG inline, sem rede e sem dependência. Expõe window.qrSvg(texto, lado, titulo).
 */
(function (global) {
  "use strict";
  var VERSOES_M = {
    1: [26, 10, 1, 16, 0, 0], 2: [44, 16, 1, 28, 0, 0], 3: [70, 26, 1, 44, 0, 0],
    4: [100, 18, 2, 32, 0, 0], 5: [134, 24, 2, 43, 0, 0], 6: [172, 16, 4, 27, 0, 0],
  };
  var ALINHAMENTO = { 1: [], 2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30], 6: [6, 34] };

  var EXP = new Uint8Array(512), LOG = new Uint8Array(256);
  (function () {
    var x = 1;
    for (var i = 0; i < 255; i++) { EXP[i] = x; LOG[x] = i; x <<= 1; if (x & 0x100) x ^= 0x11d; }
    for (var j = 255; j < 512; j++) EXP[j] = EXP[j - 255];
  })();
  function mul(a, b) { return a === 0 || b === 0 ? 0 : EXP[LOG[a] + LOG[b]]; }

  function gerador(grau) {
    var g = [1];
    for (var i = 0; i < grau; i++) {
      var novo = new Array(g.length + 1).fill(0);
      for (var jj = 0; jj < g.length; jj++) { novo[jj] ^= g[jj]; novo[jj + 1] ^= mul(g[jj], EXP[i]); }
      g = novo;
    }
    return g;
  }
  function correcao(dados, qtd) {
    var g = gerador(qtd), resto = new Array(qtd).fill(0);
    for (var k = 0; k < dados.length; k++) {
      var fator = dados[k] ^ resto[0];
      resto.shift(); resto.push(0);
      if (fator !== 0) for (var i = 0; i < qtd; i++) resto[i] ^= mul(g[i + 1], fator);
    }
    return resto;
  }
  function informacaoFormato(mascara) {
    var dados = 0 | mascara, resto = dados << 10;
    for (var i = 14; i >= 10; i--) if (resto & (1 << i)) resto ^= 0b10100110111 << (i - 10);
    return ((dados << 10) | resto) ^ 0b101010000010010;
  }

  function novaMatriz(n) { return { m: new Uint8Array(n * n), fixo: new Uint8Array(n * n), n: n }; }
  function por(mat, x, y, v, fixo) {
    if (fixo === undefined) fixo = true;
    mat.m[y * mat.n + x] = v; if (fixo) mat.fixo[y * mat.n + x] = 1;
  }
  function padroesDeFuncao(mat, versao) {
    var n = mat.n, cantos = [[0, 0], [n - 7, 0], [0, n - 7]];
    for (var c = 0; c < cantos.length; c++) {
      var ox = cantos[c][0], oy = cantos[c][1];
      for (var dy = -1; dy <= 7; dy++) for (var dx = -1; dx <= 7; dx++) {
        var x = ox + dx, y = oy + dy;
        if (x < 0 || y < 0 || x >= n || y >= n) continue;
        var borda = dx === 0 || dx === 6 || dy === 0 || dy === 6;
        var miolo = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
        por(mat, x, y, dx < 0 || dy < 0 || dx > 6 || dy > 6 ? 0 : (borda || miolo ? 1 : 0));
      }
    }
    for (var i = 8; i < n - 8; i++) { var v = i % 2 === 0 ? 1 : 0; por(mat, i, 6, v); por(mat, 6, i, v); }
    var centros = ALINHAMENTO[versao];
    for (var a = 0; a < centros.length; a++) for (var b = 0; b < centros.length; b++) {
      var cx = centros[b], cy = centros[a];
      var sobre = (cx <= 8 && cy <= 8) || (cx <= 8 && cy >= n - 9) || (cx >= n - 9 && cy <= 8);
      if (sobre) continue;
      for (var dy2 = -2; dy2 <= 2; dy2++) for (var dx2 = -2; dx2 <= 2; dx2++) {
        var anel = Math.max(Math.abs(dx2), Math.abs(dy2));
        por(mat, cx + dx2, cy + dy2, anel === 1 ? 0 : 1);
      }
    }
    por(mat, 8, n - 8, 1);
    for (var e = 0; e < 9; e++) { if (e !== 6) por(mat, e, 8, 0); if (e !== 6) por(mat, 8, e, 0); }
    for (var f = 0; f < 8; f++) { por(mat, n - 1 - f, 8, 0); if (f < 7) por(mat, 8, n - 1 - f, 0); }
  }
  function gravarFormato(mat, mascara) {
    var n = mat.n, bits = informacaoFormato(mascara);
    for (var i = 0; i < 15; i++) {
      var bit = (bits >> i) & 1;
      if (i < 6) por(mat, 8, i, bit);
      else if (i === 6) por(mat, 8, 7, bit);
      else if (i === 7) por(mat, 8, 8, bit);
      else if (i === 8) por(mat, 7, 8, bit);
      else por(mat, 14 - i, 8, bit);
      if (i < 8) por(mat, n - 1 - i, 8, bit);
      else por(mat, 8, n - 15 + i, bit);
    }
  }
  function gravarDados(mat, bits) {
    var n = mat.n, idx = 0, subindo = true;
    for (var col = n - 1; col > 0; col -= 2) {
      if (col === 6) col--;
      for (var passo = 0; passo < n; passo++) {
        var y = subindo ? n - 1 - passo : passo, cols = [col, col - 1];
        for (var ci = 0; ci < 2; ci++) {
          var x = cols[ci];
          if (mat.fixo[y * n + x]) continue;
          por(mat, x, y, idx < bits.length ? bits[idx] : 0, false); idx++;
        }
      }
      subindo = !subindo;
    }
  }
  var APLICA_MASCARA = [
    function (x, y) { return (x + y) % 2 === 0; },
    function (_x, y) { return y % 2 === 0; },
    function (x) { return x % 3 === 0; },
    function (x, y) { return (x + y) % 3 === 0; },
    function (x, y) { return (Math.floor(y / 2) + Math.floor(x / 3)) % 2 === 0; },
    function (x, y) { return ((x * y) % 2) + ((x * y) % 3) === 0; },
    function (x, y) { return (((x * y) % 2) + ((x * y) % 3)) % 2 === 0; },
    function (x, y) { return (((x + y) % 2) + ((x * y) % 3)) % 2 === 0; },
  ];
  function mascarar(mat, mascara) {
    var fora = { m: new Uint8Array(mat.m), fixo: mat.fixo, n: mat.n }, regra = APLICA_MASCARA[mascara];
    for (var y = 0; y < mat.n; y++) for (var x = 0; x < mat.n; x++) {
      if (mat.fixo[y * mat.n + x]) continue;
      if (regra(x, y)) fora.m[y * mat.n + x] ^= 1;
    }
    return fora;
  }
  function penalidade(mat) {
    var n = mat.n, em = function (x, y) { return mat.m[y * n + x]; }, total = 0;
    for (var i = 0; i < n; i++) for (var l = 0; l < 2; l++) {
      var linha = l === 0, corrida = 1;
      for (var j = 1; j < n; j++) {
        var atual = linha ? em(j, i) : em(i, j), antes = linha ? em(j - 1, i) : em(i, j - 1);
        if (atual === antes) corrida++; else { if (corrida >= 5) total += corrida - 2; corrida = 1; }
      }
      if (corrida >= 5) total += corrida - 2;
    }
    for (var y = 0; y < n - 1; y++) for (var x = 0; x < n - 1; x++) {
      var v = em(x, y);
      if (v === em(x + 1, y) && v === em(x, y + 1) && v === em(x + 1, y + 1)) total += 3;
    }
    var alvo1 = [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0], alvo2 = [0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1];
    for (var ii = 0; ii < n; ii++) for (var jj = 0; jj <= n - 11; jj++) for (var ll = 0; ll < 2; ll++) {
      var ln = ll === 0, b1 = true, b2 = true;
      for (var k = 0; k < 11; k++) {
        var vv = ln ? em(jj + k, ii) : em(ii, jj + k);
        if (vv !== alvo1[k]) b1 = false; if (vv !== alvo2[k]) b2 = false;
      }
      if (b1) total += 40; if (b2) total += 40;
    }
    var escuros = 0; for (var z = 0; z < n * n; z++) escuros += mat.m[z];
    total += Math.floor(Math.abs((escuros * 100) / (n * n) - 50) / 5) * 10;
    return total;
  }
  function escolherVersao(bytes) {
    for (var v = 1; v <= 6; v++) {
      var info = VERSOES_M[v], dados = info[2] * info[3] + info[4] * info[5];
      if (4 + 8 + bytes * 8 <= dados * 8) return v;
    }
    throw new Error("Conteúdo grande demais para QR versão 6 (" + bytes + " bytes).");
  }
  function matrizQr(texto) {
    var bytes = Array.from(new TextEncoder().encode(texto));
    var versao = escolherVersao(bytes.length), info = VERSOES_M[versao];
    var ecPorBloco = info[1], b1 = info[2], d1 = info[3], b2 = info[4], d2 = info[5];
    var totalDados = b1 * d1 + b2 * d2;
    var bits = [];
    var empurrar = function (valor, tam) { for (var i = tam - 1; i >= 0; i--) bits.push((valor >> i) & 1); };
    empurrar(0b0100, 4); empurrar(bytes.length, 8);
    for (var bi = 0; bi < bytes.length; bi++) empurrar(bytes[bi], 8);
    for (var t = 0; t < 4 && bits.length < totalDados * 8; t++) bits.push(0);
    while (bits.length % 8 !== 0) bits.push(0);
    var codewords = [];
    for (var c = 0; c < bits.length; c += 8) codewords.push(bits.slice(c, c + 8).reduce(function (acc, b) { return (acc << 1) | b; }, 0));
    var enchimento = [0xec, 0x11];
    for (var p = 0; codewords.length < totalDados; p++) codewords.push(enchimento[p % 2]);
    var blocosDados = [], blocosEc = [], pos = 0, grupos = [[b1, d1], [b2, d2]];
    for (var gi = 0; gi < grupos.length; gi++) {
      var qtd = grupos[gi][0], tam = grupos[gi][1];
      for (var q = 0; q < qtd; q++) {
        var bloco = codewords.slice(pos, pos + tam); pos += tam;
        blocosDados.push(bloco); blocosEc.push(correcao(bloco, ecPorBloco));
      }
    }
    var finais = [], maiorDado = Math.max.apply(null, blocosDados.map(function (b) { return b.length; }));
    for (var m1 = 0; m1 < maiorDado; m1++) for (var bd = 0; bd < blocosDados.length; bd++) if (m1 < blocosDados[bd].length) finais.push(blocosDados[bd][m1]);
    for (var m2 = 0; m2 < ecPorBloco; m2++) for (var be = 0; be < blocosEc.length; be++) finais.push(blocosEc[be][m2]);
    var bitsFinais = [];
    for (var ff = 0; ff < finais.length; ff++) for (var sb = 7; sb >= 0; sb--) bitsFinais.push((finais[ff] >> sb) & 1);
    var n = versao * 4 + 17, base = novaMatriz(n);
    padroesDeFuncao(base, versao); gravarDados(base, bitsFinais);
    var melhor = null, melhorNota = Infinity;
    for (var mask = 0; mask < 8; mask++) {
      var cand = mascarar(base, mask); gravarFormato(cand, mask);
      var nota = penalidade(cand);
      if (nota < melhorNota) { melhorNota = nota; melhor = cand; }
    }
    return { n: n, modulos: melhor.m };
  }
  function qrSvg(texto, lado, titulo) {
    if (titulo === undefined) titulo = "QR de validação";
    var r = matrizQr(texto), n = r.n, modulos = r.modulos, borda = 4, total = n + borda * 2, partes = [];
    for (var y = 0; y < n; y++) for (var x = 0; x < n; x++) if (modulos[y * n + x]) partes.push("M" + (x + borda) + " " + (y + borda) + "h1v1h-1z");
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + total + " " + total + '" width="' + lado + '" height="' + lado + '" role="img" aria-label="' + titulo + '" shape-rendering="crispEdges">' +
      '<rect width="' + total + '" height="' + total + '" fill="#ffffff"/><path d="' + partes.join("") + '" fill="#000000"/></svg>';
  }
  global.qrSvg = qrSvg; global.matrizQr = matrizQr;
})(typeof window !== "undefined" ? window : this);
