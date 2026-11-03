# n8n — Z-Smart-CM pages

Workflows n8n à importer (Workflows → ⋯ → *Import from File*), puis **activer**.

## 1. Vitrine — `vitrine_cm_app.workflow.json`

- URL publique une fois activée : `https://n8ntest.microzed.tn/webhook/z-smart-cm`
- Contenu : présentation de l'app (hero, fonctionnalités, 4 étapes, écrans, messages d'erreur, CTA démo), 100 % autonome (CSS inline, aucun asset externe).

Pour éditer la page :
1. modifier `vitrine.js` (HTML/CSS dans un template literal),
2. relancer `./build-vitrine-workflow.ps1` (PowerShell),
3. réimporter le JSON — ou copier directement le contenu de `vitrine.js` dans le nœud **Construire la page**.

## 2. Téléchargement APK — `apk-download.workflow.json`

- URL publique : `https://n8ntest.microzed.tn/webhook/z-smart-cm-download`
- Sert l'APK depuis le disque du serveur n8n (`/data/apk/Z-Smart-CM.apk`), en-têtes corrects pour l'installation Android.

Mise en place :
1. copier l'APK sur le serveur : `docker cp app-production-release.apk n8n:/data/apk/Z-Smart-CM.apk`
   (téléchargeable d'abord sur https://github.com/zarsalene/cm-app/releases — repo privé, login requis)
2. ajuster le chemin dans le nœud **Read APK File** si besoin,
3. activer le workflow.

## CI GitHub (dans le repo Flutter)

`.github/workflows/release.yml` : à chaque tag `v*` (ex. `git tag v0.2.0 && git push --tags`) → build APK production → GitHub Release pré-releasée avec l'APK.
⚠️ Sans `google-services.json` ajouté en secret/committé, l'APK CI tourne **sans push FCM** (l'app marche, pas de notifications).

Récupérer l'APK fraîchement buildé, puis l'installer dans n8n via les commandes ci-dessus pour mise à jour.

## Comptes des agents

La table `cm_app_users` (/n8n → Data Tables) attend `password_hash = sha256(username + ':' + password)` en hex minuscule. Pour créer un agent :

```powershell
$u="agent2"; $p="motdepasse"; $bytes=[Text.Encoding]::UTF8.GetBytes("$u`:$p"); $sha=[Security.Cryptography.SHA256]::Create(); ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
```

Ajouter la ligne (username, password_hash) dans la table — l'app se connecte immédiatement.

## Historique de sécurité

Le 2026-11-03, `password_hash` contenait un mot de passe en clair (corrigé en SHA-256). Conséquence : le mot de passe utilisateur `arsalene` a circulé en clair — à remplacer (nouveau hash recalculé avec la commande ci-dessus, mise à jour de la ligne dans la table).
