// n8n Code node — "Construire la page"
// Entrée : rien. Sortie : [{ json: { html } }]
// Le nœud « Répondre (HTML) » renvoie {{ $json.html }} avec Content-Type: text/html.
// Modifiez ce fichier puis relancez n8n/build-vitrine-with-logos.ps1 pour régénérer le JSON à importer.

const html = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Z-Smart-CM — Vendez en bot, dépannez en humain</title>
<meta name="description" content="Z-Smart-CM : l'application CM de Microzed. Quand votre bot Messenger ou WhatsApp bloque, votre agent reprend la main en une notification — puis rend la conversation au bot.">
<link rel="icon" href="data:image/png;base64,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">
<style>
  /* ===== Design System ===== */
  :root{
    --teal:#0F766E;
    --teal-glow:rgba(15,118,110,.35);
    --deep:#0B1220;
    --deep-2:#131c2e;
    --orange:#D97706;
    --orange-glow:rgba(217,119,6,.3);
    --ink:#e7edf7;
    --muted:#9aa7bd;
    --card:rgba(16,26,45,.6);
    --card-border:rgba(255,255,255,.08);
    --line:#1f2b45;
    --fb:#1877F2;
    --wa:#25D366;
    --radius:20px;
    --shadow:0 25px 50px -12px rgba(0,0,0,.5);
    --shadow-sm:0 8px 24px -4px rgba(0,0,0,.4);
    --transition:all .35s cubic-bezier(.4,0,.2,1);
    --glass:rgba(255,255,255,.03);
    --glass-border:rgba(255,255,255,.1);
  }

  /* ===== Reset ===== */
  *{margin:0;padding:0;box-sizing:border-box}
  html{scroll-behavior:smooth}
  body{
    font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
    background:var(--deep);color:var(--ink);line-height:1.6;
    -webkit-font-smoothing:antialiased;overflow-x:hidden
  }
  a{color:inherit;text-decoration:none}
  img{max-width:100%;display:block}

  /* ===== Layout ===== */
  .container{max-width:1140px;margin:0 auto;padding:0 28px}
  section{padding:96px 0}

  /* ===== Background glow ===== */
  .glow{
    position:fixed;top:0;left:0;width:100%;height:100%;
    z-index:-1;pointer-events:none;
    background:
      radial-gradient(600px 400px at 20% -10%, rgba(15,118,110,.15), transparent 50%),
      radial-gradient(500px 300px at 100% 0%, rgba(217,119,6,.1), transparent 50%),
      radial-gradient(400px 300px at 50% 100%, rgba(15,118,110,.08), transparent 50%);
  }

  /* ===== Nav ===== */
  .nav{
    position:sticky;top:0;z-index:50;
    background:rgba(11,18,32,.7);
    backdrop-filter:blur(20px);
    -webkit-backdrop-filter:blur(20px);
    border-bottom:1px solid var(--glass-border);
  }
  .nav-inner{
    display:flex;align-items:center;justify-content:space-between;
    height:72px;gap:16px
  }
  .brand{
    display:flex;align-items:center;gap:12px;
    font-weight:800;font-size:17px;color:var(--ink);
    background:linear-gradient(135deg,#fff,var(--muted));
    -webkit-background-clip:text;-webkit-text-fill-color:transparent;
    background-clip:text
  }
  .logo-img{width:36px;height:36px;border-radius:12px;display:block;filter:drop-shadow(0 4px 12px rgba(15,118,110,.4))}
  .nav-links{
    display:flex;align-items:center;gap:26px
  }
  .nav-links a{
    color:var(--muted);font-size:14px;font-weight:500;
    transition:var(--transition)
  }
  .nav-links a:hover{color:var(--ink)}
  .nav-links .btn-primary{padding:8px 18px;font-size:13px}

  /* ===== Buttons ===== */
  .btn{
    display:inline-flex;align-items:center;justify-content:center;
    gap:8px;padding:14px 26px;border-radius:14px;
    font-weight:700;font-size:15px;cursor:pointer;
    border:none;transition:var(--transition)
  }
  .btn-primary{
    background:linear-gradient(135deg,var(--orange),#b45309);
    color:#fff;box-shadow:0 10px 24px -6px var(--orange-glow)
  }
  .btn-primary:hover{
    transform:translateY(-2px);
    box-shadow:0 14px 28px -6px var(--orange-glow)
  }
  .btn-ghost{
    border:1px solid var(--glass-border);color:var(--ink);
    background:var(--glass)
  }
  .btn-ghost:hover{
    border-color:var(--muted);
    background:rgba(255,255,255,.08)
  }
  .btn-sm{padding:10px 18px;font-size:13px;border-radius:12px}

  /* ===== Hero ===== */
  .hero{
    padding:110px 0 80px;
    display:grid;
    grid-template-columns:1.2fr .9fr;
    gap:60px;
    align-items:center;
    position:relative
  }
  .hero::before{
    content:'';position:absolute;inset:0;
    background:linear-gradient(135deg,rgba(15,118,110,.1),transparent);
    z-index:-1;pointer-events:none
  }
  .hero-eyebrow{
    color:var(--orange);font-weight:800;text-transform:uppercase;
    letter-spacing:.16em;font-size:11px;display:block;
    margin-bottom:14px;opacity:.9
  }
  .hero h1{
    font-size:52px;line-height:1.1;letter-spacing:-.6px;
    margin:0 0 22px;letter-spacing:-0.6px
  }
  .hero h1 b{
    color:var(--orange);font-weight:800
  }
  .hero .lead{
    color:var(--muted);font-size:18px;margin-bottom:28px;
    max-width:540px;line-height:1.7;font-weight:400
  }
  .hero-cta{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:26px}
  .chips{
    display:flex;flex-wrap:wrap;gap:10px
  }
  .chip{
    border:1px solid var(--glass-border);border-radius:999px;
    padding:7px 14px;font-size:12.5px;color:var(--muted);
    background:rgba(255,255,255,.04);backdrop-filter:blur(8px)
  }
  .hero-visual{justify-self:center;display:flex;flex-direction:column;align-items:center;gap:24px;position:relative}
  .hero-logo{
    width:104px;height:104px;border-radius:28px;
    box-shadow:0 28px 56px -14px rgba(15,118,110,.5);
    border:1px solid var(--glass-border)
  }
  .phone{
    width:320px;border-radius:44px;
    border:14px solid #16223d;overflow:hidden;
    background:#0e172a;
    box-shadow:0 35px 70px -14px rgba(0,0,0,.6);
    border-image:linear-gradient(135deg,var(--teal),var(--orange)) 1;
  }
  .phone-head{
    background:linear-gradient(135deg,var(--teal),var(--deep));
    padding:16px;display:flex;align-items:center;gap:12px
  }
  .avatar{
    width:38px;height:38px;background:rgba(255,255,255,.15);
    border-radius:14px;color:var(--teal);font-weight:900;
    display:flex;align-items:center;justify-content:center;
    border:1px solid rgba(255,255,255,.2)
  }
  .phone-head .t{font-weight:800;font-size:15px;color:#fff}
  .phone-head .st{font-size:11px;color:rgba(255,255,255,.7)}
  .phone-body{
    padding:14px;display:flex;flex-direction:column;gap:12px;
    min-height:360px
  }
  .row{
    background:rgba(255,255,255,.04);
    border:1px solid var(--glass-border);
    border-radius:14px;padding:12px;display:flex;gap:12px;align-items:center;
    backdrop-filter:blur(8px)
  }
  .row:hover{border-color:var(--muted)}
  .platform{
    flex:none;width:30px;height:30px;border-radius:10px;
    display:flex;align-items:center;justify-content:center;
    color:#fff;font-size:11px;font-weight:800
  }
  .platform-fb{background:var(--fb)}
  .platform-wa{background:var(--wa)}
  .row .info{min-width:0}
  .name{font-weight:700;font-size:13px;color:var(--ink)}
  .why{
    color:var(--muted);font-size:12px;
    white-space:nowrap;overflow:hidden;text-overflow:ellipsis
  }
  .time{
    margin-left:auto;color:var(--muted);font-size:11px;white-space:nowrap
  }
  .dot{
    flex:none;width:10px;height:10px;border-radius:99px;background:var(--orange);
    box-shadow:0 0 8px var(--orange)
  }
  .dot-closed{background:#3b4a66;box-shadow:none}
  .mock-cap{
    color:var(--muted);font-size:12px;text-align:center;margin-top:14px
  }

  /* ===== Section headings ===== */
  .eyebrow{
    color:var(--orange);font-weight:800;text-transform:uppercase;
    letter-spacing:.18em;font-size:11px;display:block;
    margin-bottom:12px;opacity:.9
  }
  h2{
    font-size:36px;letter-spacing:-.4px;margin:0 0 18px
  }
  .sub{
    color:var(--muted);max-width:660px;margin-bottom:48px;
    line-height:1.7;font-size:17px;font-weight:400
  }

  /* ===== Cards grid ===== */
  .grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(260px,1fr));
    gap:20px
  }
  .card{
    background:var(--glass);
    border:1px solid var(--glass-border);
    border-radius:var(--radius);
    padding:28px;
    transition:var(--transition);
    backdrop-filter:blur(12px)
  }
  .card:hover{
    border-color:var(--teal);
    transform:translateY(-4px);
    box-shadow:var(--shadow-sm)
  }
  .icon{
    width:52px;height:52px;background:rgba(15,118,110,.12);
    border:1px solid rgba(15,118,110,.25);
    border-radius:16px;display:flex;align-items:center;
    justify-content:center;font-size:24px;margin-bottom:20px;
    color:var(--teal);transition:var(--transition)
  }
  .card:hover .icon{
    background:var(--teal);color:#fff;border-color:var(--teal)
  }
  .card h3{
    font-size:17px;margin:0 0 10px;color:var(--ink)
  }
  .card p{
    color:var(--muted);font-size:14.5px;line-height:1.6;margin:0
  }

  /* ===== Steps ===== */
  .steps{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(240px,1fr));
    gap:20px
  }
  .step{
    background:var(--glass);
    border:1px solid var(--glass-border);
    border-radius:var(--radius);
    padding:28px;
    transition:var(--transition);
    backdrop-filter:blur(12px);position:relative;overflow:hidden
  }
  .step::before{
    content:'';position:absolute;top:0;left:0;width:100%;height:3px;
    background:linear-gradient(90deg,var(--teal),var(--orange));
    transform:scaleX(0);transition:var(--transition)
  }
  .step:hover::before{transform:scaleX(1)}
  .step:hover{
    border-color:var(--teal);
    transform:translateY(-4px);
    box-shadow:var(--shadow-sm)
  }
  .num{
    width:36px;height:36px;border-radius:50%;
    background:linear-gradient(135deg,var(--teal),var(--deep));
    color:#fff;font-weight:800;display:flex;
    align-items:center;justify-content:center;
    margin-bottom:20px;font-size:15px;box-shadow:0 8px 20px -4px var(--teal-glow)
  }
  .step h3{font-size:16px;margin:0 0 10px;color:var(--ink)}
  .step p{color:var(--muted);font-size:14.5px;line-height:1.6;margin:0}
  .note{
    margin-top:32px;color:var(--muted);font-size:13px;line-height:1.6
  }

  /* ===== Screens ===== */
  .screens{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(340px,1fr));
    gap:48px;margin-top:48px;justify-items:center
  }
  .chat{
    display:flex;flex-direction:column;gap:10px;min-height:360px
  }
  .msg{
    max-width:82%;padding:12px 16px;border-radius:16px;
    font-size:13.5px;line-height:1.5
  }
  .msg-client{
    background:rgba(255,255,255,.05);
    border:1px solid var(--glass-border);
    align-self:flex-start;border-bottom-left-radius:4px
  }
  .msg-cm{
    background:var(--teal);
    align-self:flex-end;border-bottom-right-radius:4px;color:#fff
  }
  .giveback{
    margin-top:auto;background:transparent;
    border:1px dashed var(--orange);color:var(--orange);
    padding:12px;border-radius:14px;
    text-align:center;font-size:13px;font-weight:700;
    transition:var(--transition)
  }
  .giveback:hover{background:rgba(217,119,6,.1);border-style:solid}

  /* ===== Error / FAQ ===== */
  .errs{
    margin-top:32px;display:grid;gap:14px
  }
  .err{
    background:var(--glass);
    border:1px solid var(--glass-border);
    border-radius:16px;
    padding:20px;display:flex;gap:14px;align-items:flex-start;
    backdrop-filter:blur(12px)
  }
  .err b{
    color:var(--ink);font-size:15px;font-weight:700;
    min-width:280px;line-height:1.5
  }
  .err span{color:var(--muted);font-size:14px;line-height:1.5}

  /* ===== CTA band ===== */
  .band{
    margin:80px 0 0;
    background:linear-gradient(135deg,var(--teal),var(--deep));
    border-radius:28px;padding:48px;
    display:flex;align-items:center;justify-content:space-between;
    gap:32px;flex-wrap:wrap;
    border:1px solid var(--glass-border);
    box-shadow:var(--shadow)
  }
  .band h3{
    font-size:26px;color:#fff;margin:0 0 10px;line-height:1.3
  }
  .band p{
    color:rgba(255,255,255,.85);font-size:15px;margin:0;
    max-width:440px;line-height:1.6
  }

  /* ===== Footer ===== */
  footer{
    border-top:1px solid var(--glass-border);
    margin-top:96px;padding:56px 0;
    color:var(--muted);font-size:13px
  }
  .foot-inner{
    display:flex;justify-content:space-between;gap:20px;flex-wrap:wrap
  }
  footer a{color:var(--muted)}
  footer a:hover{color:var(--ink)}
  .foot-logo{
    width:20px;height:20px;border-radius:6px;
    vertical-align:middle;margin-right:10px;border:1px solid var(--glass-border)
  }

  /* ===== Responsive ===== */
  @media (max-width:1024px){
    .hero{grid-template-columns:1fr;padding:80px 0 64px;gap:48px}
    .hero h1{font-size:40px}
    .hero-visual{order:-1}
    .phone{width:270px}
  }
  @media (max-width:768px){
    .container{padding:0 20px}
    section{padding:72px 0}
    .hero-cta{flex-direction:column}
    .hero-cta .btn{width:100%}
    .nav-links a:not(.btn-primary){display:none}
    .foot-inner{flex-direction:column;align-items:flex-start;gap:16px}
    .band{padding:36px;flex-direction:column;align-items:flex-start}
    .band p{max-width:100%}
    .err b{min-width:auto}
  }
</style>
</head>
<body>
<div class="glow"></div>

<nav class="nav">
  <div class="container nav-inner">
    <a class="brand" href="#top">
      <img class="logo-img" src="data:image/png;base64,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" alt="Z-Smart-CM">
      Z-Smart-CM
    </a>
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
    <div class="hero-visual">
      <img class="hero-logo" src="data:image/png;base64,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" alt="Z-Smart-CM logo">
      <div class="phone">
        <div class="phone-head">
          <div class="avatar">Z</div>
          <div>
            <div class="t">Z-Smart-CM</div>
            <div class="st">Escalations — 2 ouvertes</div>
          </div>
        </div>
        <div class="phone-body">
          <div class="row">
            <div class="platform platform-fb">FB</div>
            <div class="info">
              <div class="name">Nour Jlassi</div>
              <div class="why">Paiement COD ambigu</div>
            </div>
            <span class="time">il y a 2 min</span>
            <span class="dot"></span>
          </div>
          <div class="row">
            <div class="platform platform-wa">WA</div>
            <div class="info">
              <div class="name">Slim Gharbi</div>
              <div class="why">Négociation sur le prix</div>
            </div>
            <span class="time">il y a 6 min</span>
            <span class="dot"></span>
          </div>
          <div class="row">
            <div class="platform platform-fb">FB</div>
            <div class="info">
              <div class="name">Amel Ben Ali</div>
              <div class="why">Adresse introuvable</div>
            </div>
            <span class="time">hier</span>
            <span class="dot dot-closed"></span>
          </div>
        </div>
      </div>
      <p class="mock-cap">Aperçu — liste des escalations</p>
    </div>
    <div>
      <span class="hero-eyebrow">L'application compagnon de vos agents de vente</span>
      <h1>Vendez en bot.<br><b>Dépannez en humain.</b></h1>
      <p class="lead">Z-Smart-CM alerte votre Community Manager dès qu'une conversation Messenger ou WhatsApp lui échappe. Il prend la main, répond, et rend la conversation au bot en un clic.</p>
      <div class="hero-cta">
        <a class="btn btn-primary" href="https://n8ntest.microzed.tn/webhook/z-smart-cm-download" rel="noopener">Télécharger l'APK</a>
        <a class="btn btn-ghost" href="#how" rel="noopener">Voir le fonctionnement</a>
      </div>
      <div class="chips">
        <span class="chip">🔔 Alertes push</span>
        <span class="chip">💬 Messenger + WhatsApp</span>
        <span class="chip">🔁 Rendre au bot</span>
        <span class="chip">🔐 Session sécurisée</span>
      </div>
    </div>
  </div>
</header>

<section id="features" class="container">
  <span class="eyebrow">Fonctionnalités</span>
  <h2>Tout pour ne perdre aucun client</h2>
  <p class="sub">Le bot gère le volume, votre équipe gère la nuance. Z-Smart-CM relie les deux sans changer d'outil.</p>
  <div class="grid">
    <div class="card">
      <span class="icon">🔔</span>
      <h3>Alerte instantanée</h3>
      <p>Push dès l'escalade : motif, canal et nom du client, statut ouvert ou clôturé, en un coup d'œil.</p>
    </div>
    <div class="card">
      <span class="icon">💬</span>
      <h3>Conversation 1:1</h3>
      <p>L'historique complet du chat s'ouvre en un tap : client à gauche, bot et CM à droite.</p>
    </div>
    <div class="card">
      <span class="icon">⚡</span>
      <h3>Réponse directe</h3>
      <p>Votre message part immédiatement vers Messenger ou WhatsApp depuis l'app, rien à copier-coller.</p>
    </div>
    <div class="card">
      <span class="icon">🔁</span>
      <h3>Rendre au bot</h3>
      <p>Terminé ? Un bouton remet l'automatisation en marche et clôt l'escalade.</p>
    </div>
    <div class="card">
      <span class="icon">🔐</span>
      <h3>Sessions sécurisées</h3>
      <p>Un compte par agent, un token qui expire, reconnexion automatique à l'ouverture.</p>
    </div>
    <div class="card">
      <span class="icon">📱</span>
      <h3>Deux canaux natifs</h3>
      <p>Facebook Messenger et WhatsApp Business, une seule interface.</p>
    </div>
  </div>
</section>

<section id="how" class="container">
  <span class="eyebrow">Fonctionnement</span>
  <h2>Quatre étapes, aucune rupture</h2>
  <p class="sub">Du déclenchement du bot jusqu'à la reprise de l'automatisation, la conversation suit toujours le même chemin.</p>
  <div class="steps">
    <div class="step">
      <div class="num">1</div>
      <h3>Le bot lève une alerte</h3>
      <p>Paiement, négociation, ambiguïté… le motif remonte via l'app, avec le canal et le client concerné.</p>
    </div>
    <div class="step">
      <div class="num">2</div>
      <h3>L'agent prend la main</h3>
      <p>Notification push instantanée. Il ouvre la conversation avec l'historique complet déjà chargé.</p>
    </div>
    <div class="step">
      <div class="num">3</div>
      <h3>Réponse humaine</h3>
      <p>Il écrit depuis Z-Smart-CM ; le message est envoyé sur Messenger ou WhatsApp pour le client.</p>
    </div>
    <div class="step">
      <div class="num">4</div>
      <h3>Le bot reprend</h3>
      <p>Un clic sur « Rendre au bot » : l'escalade est marquée close et l'automatisation reprend l'affaire.</p>
    </div>
  </div>
  <p class="note">🔒 Aucune donnée client ne sort de l'app : la conversation n'est visible que d'un agent connecté.</p>
</section>

<section id="screens" class="container">
  <span class="eyebrow">Les écrans</span>
  <h2>Pensé pour aller vite sur mobile</h2>
  <p class="sub">Deux écrans, zéro friction : lire la file d'escalations ou répondre dans le fil.</p>
  <div class="screens">
    <div>
      <div class="phone">
        <div class="phone-head">
          <div class="avatar">Z</div>
          <div>
            <div class="t">Slim Gharbi</div>
            <div class="st">WhatsApp • reprise par l'agent</div>
          </div>
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
  <span class="eyebrow">Pour l'équipe</span>
  <h2>Trois messages, que faire ?</h2>
  <p class="sub">Les seuls messages que l'app peut afficher en cas de souci — et la solution.</p>
  <div class="errs">
    <div class="err">
      <b>« Identifiant ou mot de passe incorrect »</b>
      <span>Les comptes sont créés par l'administrateur Microzed (dans n8n). Vérifiez vos identifiants avec lui.</span>
    </div>
    <div class="err">
      <b>« Pas de connexion »</b>
      <span>Le téléphone ne rejoint pas le serveur : vérifiez le réseau ou le Wi-Fi, puis relancez la connexion.</span>
    </div>
    <div class="err">
      <b>« Erreur, réessayez »</b>
      <span>Côté serveur, un souci temporaire. Attendez quelques secondes et relancez.</span>
    </div>
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
    <span>
      <img src="data:image/jpeg;base64,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" alt="Microzed" height="20" style="vertical-align:middle;margin-right:10px;border-radius:6px">
      Microzed © 2026 — Z-Smart-CM : encadrer le bot sans quitter la conversation.
    </span>
    <a href="https://microzed.tn" target="_blank" rel="noopener">microzed.tn</a>
  </div>
</footer>
</body>
</html>`;

return [{ json: { html } }];
