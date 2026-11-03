// n8n Code node — "Construire la page"
// Entrée : rien. Sortie : [{ json: { html } }]
// Le nœud « Répondre (HTML) » renvoie {{ $json.html }} avec Content-Type: text/html.
// Modifiez ce fichier puis relancez n8n/build-vitrine-workflow.ps1 pour régénérer le JSON à importer.

const html = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Z-Smart-CM — Vendez en bot, dépannez en humain</title>
<meta name="description" content="Z-Smart-CM : l'application CM de Microzed. Quand votre bot Messenger ou WhatsApp bloque, votre agent reprend la main en une notification — puis rend la conversation au bot.">
<link rel="icon" href="__APP_ICON__">
<style>
*{margin:0;padding:0;box-sizing:border-box}
:root{--teal:#0F766E;--deep:#134e4a;--orange:#D97706;--ink:#e7edf7;--muted:#9aa7bd;--card:#101a2d;--line:#1f2b45;--fb:#1877F2;--wa:#25D366}
html{scroll-behavior:smooth}
body{font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;background:#0B1220;color:var(--ink);line-height:1.6}
.container{max-width:1060px;margin:0 auto;padding:0 24px}
.nav{position:sticky;top:0;z-index:10;background:rgba(11,18,32,.85);backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}
.nav-inner{display:flex;align-items:center;justify-content:space-between;height:64px;gap:16px}
.brand{display:flex;align-items:center;gap:10px;font-weight:800;font-size:16px;color:var(--ink);text-decoration:none}
.logo-img{width:34px;height:34px;border-radius:10px;display:block}
.nav-links{display:flex;align-items:center;gap:22px}
.nav-links a{color:var(--muted);text-decoration:none;font-size:14px}
.nav-links a:hover{color:var(--ink)}
.btn{display:inline-flex;align-items:center;gap:8px;padding:12px 22px;border-radius:12px;font-weight:700;font-size:15px;text-decoration:none;cursor:pointer}
.btn-primary{background:var(--orange);color:#fff}
.btn-primary:hover{background:#b45309}
.btn-ghost{border:1px solid var(--line);color:var(--ink)}
.btn-ghost:hover{border-color:var(--muted)}
.btn-sm{padding:9px 16px;font-size:13px;border-radius:10px}
.hero-logo{width:84px;height:84px;border-radius:20px;margin-bottom:20px;box-shadow:0 12px 30px rgba(15,118,110,.35)}
.eyebrow{color:var(--orange);font-weight:800;text-transform:uppercase;letter-spacing:.1em;font-size:12px}
h1{font-size:44px;line-height:1.12;letter-spacing:-.5px;margin:12px 0 18px}
.lead{color:var(--muted);font-size:18px;margin-bottom:28px;max-width:520px}
.hero-cta{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:26px}
.chips{display:flex;flex-wrap:wrap;gap:10px}
.chip{border:1px solid var(--line);border-radius:999px;padding:6px 13px;font-size:13px;color:var(--muted)}
.hero-visual{justify-self:center}
.phone{width:300px;border-radius:36px;border:10px solid #1b2740;overflow:hidden;background:#0d1526;box-shadow:0 30px 60px rgba(0,0,0,.45)}
.phone-head{background:linear-gradient(135deg,var(--teal),var(--deep));padding:14px;display:flex;align-items:center;gap:10px}
.avatar{width:34px;height:34px;background:#fff;border-radius:12px;color:var(--teal);font-weight:900;display:flex;align-items:center;justify-content:center}
.phone-head .t{font-weight:800;font-size:14px;color:#fff}
.phone-head .st{font-size:11px;color:rgba(255,255,255,.75)}
.phone-body{padding:12px;display:flex;flex-direction:column;gap:10px;min-height:330px}
.row{background:#121d33;border:1px solid var(--line);border-radius:12px;padding:10px;display:flex;gap:10px;align-items:center}
.platform{flex:none;width:28px;height:28px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:11px;font-weight:800}
.platform-fb{background:var(--fb)}
.platform-wa{background:var(--wa)}
.row .info{min-width:0}
.name{font-weight:700;font-size:13px}
.why{color:var(--muted);font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.time{margin-left:auto;color:var(--muted);font-size:11px;white-space:nowrap}
.dot{flex:none;width:9px;height:9px;border-radius:99px;background:var(--orange)}
.dot-closed{background:#3b4a66}
.mock-cap{color:var(--muted);font-size:13px;margin-top:14px;text-align:center}
section{padding:64px 0}
h2{font-size:30px;letter-spacing:-.3px;margin:8px 0 12px}
.sub{color:var(--muted);max-width:640px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px;margin-top:32px}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:20px}
.icon{font-size:22px}
.card h3{font-size:17px;margin:10px 0 6px}
.card p{color:var(--muted);font-size:14px}
.steps{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin-top:32px}
.step{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:20px}
.num{width:28px;height:28px;border-radius:99px;background:var(--teal);color:#fff;font-weight:800;display:flex;align-items:center;justify-content:center;margin-bottom:12px;font-size:14px}
.step h3{font-size:16px;margin-bottom:6px}
.step p{color:var(--muted);font-size:14px}
.note{margin-top:20px;color:var(--muted);font-size:13px}
.screens{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:36px;margin-top:36px;justify-items:center}
.chat{display:flex;flex-direction:column;gap:8px;min-height:330px}
.msg{max-width:82%;padding:9px 12px;border-radius:14px;font-size:12.5px}
.msg-client{background:#1a2743;align-self:flex-start;border-bottom-left-radius:4px}
.msg-cm{background:var(--teal);align-self:flex-end;border-bottom-right-radius:4px;color:#fff}
.giveback{margin-top:auto;background:transparent;border:1px dashed var(--orange);color:var(--orange);padding:9px;border-radius:12px;text-align:center;font-size:12.5px;font-weight:700}
.errs{margin-top:28px;display:grid;gap:12px}
.err{display:grid;grid-template-columns:1fr;gap:4px;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px}
.err b{color:var(--ink)}
.err span{color:var(--muted);font-size:14px}
.band{margin:64px 0 0;background:linear-gradient(135deg,var(--teal),var(--deep));border-radius:20px;padding:36px;display:flex;align-items:center;justify-content:space-between;gap:20px;flex-wrap:wrap}
.band h3{font-size:24px;color:#fff;margin-bottom:6px}
.band p{color:rgba(255,255,255,.8);font-size:14px}
footer{border-top:1px solid var(--line);margin-top:56px;padding:28px 0;color:var(--muted);font-size:13px}
.foot-inner{display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap}
footer a{color:var(--muted)}
@media (max-width:860px){.hero{grid-template-columns:1fr;padding-top:48px;gap:32px}h1{font-size:32px}.nav-links a{display:none}.band{padding:28px}}
</style>
</head>
<body>
<nav class="nav">
  <div class="container nav-inner">
    <a class="brand" href="#top"><span class="logo">Z</span>Z-Smart-CM</a>
    <div class="nav-links">
      <a href="#features">Fonctionnalités</a>
      <a href="#how">Fonctionnement</a>
      <a href="#screens">Les écrans</a>
      <a class="btn btn-primary btn-sm" href="https://n8ntest.microzed.tn/webhook/z-smart-cm-download" rel="noopener">Télécharger l'APK</a>
    </div>
  </div>
</nav>

<header class="container" id="top">
  <div class="hero">
    <div>
      <p class="eyebrow">L'application compagnon de vos agents de vente</p>
      <h1>Vendez en bot.<br>Dépannez en humain.</h1>
      <p class="lead">Z-Smart-CM alerte votre Community Manager dès qu'une conversation Messenger ou WhatsApp lui échappe. Il prend la main, répond, et rend la conversation au bot en un clic.</p>
      <div class="hero-cta">
        <a class="btn btn-primary" href="https://n8ntest.microzed.tn/webhook/z-smart-cm-download" rel="noopener">Télécharger l'APK</a>
        <a class="btn btn-ghost" href="#how">Voir le fonctionnement</a>
      </div>
      <div class="chips">
        <span class="chip">🔔 Alertes push</span>
        <span class="chip">💬 Messenger + WhatsApp</span>
        <span class="chip">🔁 Rendre au bot</span>
        <span class="chip">🔐 Session sécurisée</span>
      </div>
    </div>
    <div class="hero-visual">
      <div class="phone">
        <div class="phone-head">
          <div class="avatar">Z</div>
          <div><div class="t">Z-Smart-CM</div><div class="st">Escalations — 2 ouvertes</div></div>
        </div>
        <div class="phone-body">
          <div class="row">
            <div class="platform platform-fb">FB</div>
            <div class="info"><div class="name">Nour Jlassi</div><div class="why">Paiement COD ambigu</div></div>
            <span class="time">il y a 2 min</span>
            <span class="dot"></span>
          </div>
          <div class="row">
            <div class="platform platform-wa">WA</div>
            <div class="info"><div class="name">Slim Gharbi</div><div class="why">Négociation sur le prix</div></div>
            <span class="time">il y a 6 min</span>
            <span class="dot"></span>
          </div>
          <div class="row">
            <div class="platform platform-fb">FB</div>
            <div class="info"><div class="name">Amel Ben Ali</div><div class="why">Adresse introuvable</div></div>
            <span class="time">hier</span>
            <span class="dot dot-closed"></span>
          </div>
        </div>
      </div>
      <p class="mock-cap">Aperçu — liste des escalations</p>
    </div>
  </div>
</header>

<section id="features" class="container">
  <p class="eyebrow">Fonctionnalités</p>
  <h2>Tout pour ne perdre aucun client</h2>
  <p class="sub">Le bot gère le volume, votre équipe gère la nuance. Z-Smart-CM relie les deux sans changer d'outil.</p>
  <div class="grid">
    <div class="card"><div class="icon">🔔</div><h3>Alerte instantanée</h3><p>Push dès l'escalade : motif, canal et nom du client, statut ouvert ou clôturé, en un coup d'œil.</p></div>
    <div class="card"><div class="icon">💬</div><h3>Conversation 1:1</h3><p>L'historique complet du chat s'ouvre en un tap : client à gauche, bot et CM à droite.</p></div>
    <div class="card"><div class="icon">⚡</div><h3>Réponse directe</h3><p>Votre message part immédiatement vers Messenger ou WhatsApp depuis l'app, rien à copier-coller.</p></div>
    <div class="card"><div class="icon">🔁</div><h3>Rendre au bot</h3><p>Terminé ? Un bouton remet l'automatisation en marche et clôt l'escalade.</p></div>
    <div class="card"><div class="icon">🔐</div><h3>Sessions sécurisées</h3><p>Un compte par agent, un token qui expire, reconnexion automatique à l'ouverture.</p></div>
    <div class="card"><div class="icon">📱</div><h3>Deux canaux natifs</h3><p>Facebook Messenger et WhatsApp Business, une seule interface.</p></div>
  </div>
</section>

<section id="how" class="container">
  <p class="eyebrow">Fonctionnement</p>
  <h2>Quatre étapes, aucune rupture</h2>
  <p class="sub">Du déclenchement du bot jusqu'à la reprise de l'automatisation, la conversation suit toujours le même chemin.</p>
  <div class="steps">
    <div class="step"><div class="num">1</div><h3>Le bot lève une alerte</h3><p>Paiement, négociation, ambiguïté… le motif remonte via l'app, avec le canal et le client concerné.</p></div>
    <div class="step"><div class="num">2</div><h3>L'agent prend la main</h3><p>Notification push instantanée. Il ouvre la conversation avec l'historique complet déjà chargé.</p></div>
    <div class="step"><div class="num">3</div><h3>Réponse humaine</h3><p>Il écrit depuis Z-Smart-CM ; le message est envoyé sur Messenger ou WhatsApp pour le client.</p></div>
    <div class="step"><div class="num">4</div><h3>Le bot reprend</h3><p>Un clic sur « Rendre au bot » : l'escalade est marquée close et l'automatisation reprend l'affaire.</p></div>
  </div>
  <p class="note">🔒 Aucune donnée client ne sort de l'app : la conversation n'est visible que d'un agent connecté.</p>
</section>

<section id="screens" class="container">
  <p class="eyebrow">Les écrans</p>
  <h2>Pensé pour aller vite sur mobile</h2>
  <p class="sub">Deux écrans, zéro friction : lire la file d'escalations ou répondre dans le fil.</p>
  <div class="screens">
    <div>
      <div class="phone">
        <div class="phone-head">
          <div class="avatar">Z</div>
          <div><div class="t">Slim Gharbi</div><div class="st">WhatsApp • reprise par l'agent</div></div>
        </div>
        <div class="phone-body chat">
          <div class="msg msg-client">Pouvez-vous faire 200 au lieu de 250 ?</div>
          <div class="msg msg-cm">On peut faire 230 au lieu de 250, envoyé en COD ☺</div>
          <div class="msg msg-client">D'accord, je prends !</div>
          <div class="msg msg-cm">Parfait, la commande est confirmée. 🧾</div>
          <div class="giveback">↩ Rendre au bot</div>
        </div>
      </div>
      <p class="mock-cap">Aperçu — conversation reprise, puis rendue au bot</p>
    </div>
  </div>
</section>

<section id="aide" class="container">
  <p class="eyebrow">Pour l'équipe</p>
  <h2>Trois messages, que faire ?</h2>
  <p class="sub">Les seuls messages que l'app peut afficher en cas de souci — et la solution.</p>
  <div class="errs">
    <div class="err"><b>« Identifiant ou mot de passe incorrect »</b><span>Les comptes sont créés par l'administrateur Microzed (dans n8n). Vérifiez vos identifiants avec lui.</span></div>
    <div class="err"><b>« Pas de connexion »</b><span>Le téléphone ne rejoint pas le serveur : vérifiez le réseau ou le Wi-Fi, puis relancez la connexion.</span></div>
    <div class="err"><b>« Erreur, réessayez »</b><span>Côté serveur, un souci temporaire. Attendez quelques secondes et relancez.</span></div>
  </div>
</section>

<div class="container" id="contact">
  <div class="band">
    <div>
      <h3>Prêt à ne plus perdre un client en route ?</h3>
      <p>Démonstration gratuite avec vos propres conversations Messenger &amp; WhatsApp.</p>
    </div>
    <a class="btn btn-primary" href="https://n8ntest.microzed.tn/webhook/z-smart-cm-download" rel="noopener">Télécharger l'APK →</a>
  </div>
</div>

<footer>
  <div class="container foot-inner">
    <span>Microzed © 2026 — Z-Smart-CM : encadrer le bot sans quitter la conversation.</span>
    <a href="https://microzed.tn" target="_blank" rel="noopener">microzed.tn</a>
  </div>
</footer>
</body>
</html>`;

return [{ json: { html } }];
