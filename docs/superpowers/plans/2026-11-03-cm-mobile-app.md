# CM Mobile App v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. One subagent per task. Steps use `- [ ]`. First action of Task N1: copy this file to `Work\CM_APP\docs\superpowers\plans\2026-11-03-cm-mobile-app.md`; briefs point to that copy.

**Goal:** Android Flutter app for CMs: FCM push on bot escalation, chat view, reply, "give back to bot". Tested on BotGenius only.

**Architecture:** n8n gets one new API workflow (one webhook, one auth gate, a Switch on `action`) and one escalation sub-workflow (pause bot in MySQL, log escalation, FCM topic push, old WhatsApp CM alert). The BotGenius build and the WhatsApp test build call that sub-workflow instead of the handoff stub. The app talks only to the API webhook over HTTPS.

**Tech Stack:** n8n (MySQL node, Data Tables, HTTP Request, Crypto, WhatsApp node), Python build scripts (same style as `scripts/build_bosphore_fb.py`), Flutter + flutter_bloc + go_router + http + json_serializable + firebase_messaging + flutter_secure_storage + very_good_analysis.

**Spec:** `PROJECTS_N8N/ideas/cm-mobile-app.md` (final).

## Facts found (do not re-derive)
- BotGenius build stubs the handoff: `patch_sim_safety` (`scripts/build_bosphore_fb.py:163-173`) replaces `Handoff Check1` with a Code node: no pause, no alert. Simulator must keep this stub.
- Bot mode for the MySQL builds = MySQL `sales_bot_user_ai_control` (`sender_id, platform, ai_enabled, disabled_by, escalated_at, label, last_message, last_seen`). BotGenius reads it in node `Find documents`, branches on `ai_enabled` in node `If`. Upsert SQL to reuse: `SQL_UPSERT_AI_CONTROL_OFF` / `_ON` in `scripts/build_whatsapp_mysql.py:141-147`.
- Handoff Manager static data `mode_<userId>_<platform>` is used only by the live v2/v3 bots. v1 does not touch Handoff Manager (live). It moves to the live path only after the BotGenius test (out of this plan).
- Chat history: `chat_sessions (platform_id 1=whatsapp, 2=facebook, session_id=sender)` → `conversations` → `messages (conversation_id, sender 'user'|'bot', message)`. Copy the join from node `Load Chat History` in `workflows/bosphore_fb/bosphore_fb_botgenius.json`.
- MySQL param style: `SUBSTRING($1, 3)` with `'s:' + v` replacements (see node `Find documents`). Copy the MySQL credential from node `Upsert user_ai_control`.
- FB send: `POST https://graph.facebook.com/v25.0/me/messages`, credential "BotGenius page token" (id = `botgenius_cred` in `workflows/bosphore_fb/pushed_ids.json`).
- Old CM alert: WhatsApp node `Send message` in Human Handoff Manager: `phoneNumberId 1140381445805651`, `recipientPhoneNumber 21690431500`, text = `notifText` format of node `Set Mode + Notify CM`.
- n8n base URL: `https://n8ntest.microzed.tn`. Push API pattern: `scripts/push_bosphore_fb.py` (`api()`, `upsert()`, data-table create).

## Global Constraints
- Test on BotGenius page `1022637774276560` only. Never send to Le Bosphore page `403896149746821`. The API reply route for `facebook` uses the BotGenius credential only.
- Claude never queries MySQL. Only n8n nodes do.
- Before any n8n push: `SendMessage` to session `projects-n8n-aa` and wait for OK. Never run `push_bosphore_fb.py`; ask that session to rebuild + push BotGenius.
- Every API action except `login` passes the auth gate. 401 body `{"error":"unauthorized"}`.
- Keep the WhatsApp CM alert; FCM push runs next to it. Either one failing must not stop the other or the pause (`onError: continueRegularOutput`).
- Max 10 tests in total (counted below). Push payload holds no customer name or text (no data without login).
- `*.jks`, `key.properties`, `google-services.json` in `CM_APP/.gitignore`. Never commit them.
- Main session never writes Flutter code. Subagents return: changed files, check result, blockers.

## API contract (one webhook)
`POST https://n8ntest.microzed.tn/webhook/cm-app` · header `Authorization: Bearer <token>` (not for login) · JSON body `{"action": ..., ...}`

| action | request extra | 200 response |
|---|---|---|
| `login` | `username, password` | `{"token","username","expires_at"}` · bad → 401 `{"error":"invalid_login"}` |
| `escalations` | – | `{"items":[{"sender_id","platform","customer_name","reason","escalated_at","status"}]}` (open first, newest first, max 50) |
| `chat` | `sender_id, platform` | `{"sender_id","platform","customer_name","reason","mode":"human"\|"bot","messages":[{"role":"customer"\|"bot","text","at"}]}` (last 100, oldest first) |
| `reply` | `sender_id, platform, text` (1..2000 chars) | `{"ok":true}` · send error → 502 `{"error":"send_failed","detail"}` |
| `give_back` | `sender_id, platform` | `{"ok":true,"mode":"bot"}` (idempotent) |
| `logout` | – | `{"ok":true}` |
| unknown | – | 400 `{"error":"bad_action"}` |
`platform` ∈ `facebook`, `whatsapp`; else 400 `{"error":"bad_request"}`.

n8n Data Tables (created by push script): `cm_app_users(username, password_hash)` with `password_hash = sha256(username + ':' + password)` hex; `cm_app_sessions(token, username, expires_at)`; `cm_app_escalations(sender_id, platform, customer_name, reason, escalated_at, status 'open'|'closed')`.
Token: Crypto node random 48 chars, TTL 30 days. FCM: topic `cm_bosphore`, `POST https://fcm.googleapis.com/v1/projects/{FCM_PROJECT_ID}/messages:send`, credential type Google Service Account (scope `https://www.googleapis.com/auth/firebase.messaging`), body `{"message":{"topic":"cm_bosphore","notification":{"title":"Escalade client","body":"Un client Facebook|WhatsApp attend un CM"},"data":{"sender_id","platform"},"android":{"priority":"high"}}}`.

## Review Focus
1. Token expired mid-session → any 401 sends the app to login, no crash. (test 5)
2. Reply outside the 24h window → Graph error → 502 → app shows "Envoi impossible", text stays in the field. (test 7)
3. Push tapped while app killed → `getInitialMessage` opens the right chat. (manual check in owner step O6)
4. `customer_name` empty → show `Client …<last 4 of sender_id>`. (folded into test 8)
5. Arabic / emoji reply → body sent as UTF-8 JSON, shown intact in Messenger. (manual check O6)

## Tests (10 max)
n8n: T1 `test_cm_app_build.py` structure test (auth gate covers every non-login route; reply never targets page 403896149746821) · T2 `smoke_cm_app.py` live (no token → 401, bad login → 401, give_back → mode bot).
Flutter: T3 api 401 → `UnauthorizedException` · T4 login reject → `LoginFailure` · T5 401 during session → `AuthBloc` emits unauthenticated · T6 reply success appends message · T7 reply 502 → error state, text kept · T8 give_back → `mode == ChatMode.bot` · T9 chat page widget: shows name/reason/channel (fallback name) · T10 spare.

---

## n8n tasks (folder `PROJECTS_N8N`)

### Task 1: (N1) API workflow + data tables — Opus, high
**Files:** Create `scripts/build_cm_app.py`, `scripts/push_cm_app.py`, `scripts/test_cm_app_build.py`, `workflows/cm_app/cm_app_api.json` (generated), `workflows/cm_app/README.md` (5 lines).
**Produces:** workflow "CM App API", webhook path `cm-app`, contract above; `workflows/cm_app/pushed_ids.json` keys `api`, `escalate`, `t_users`, `t_sessions`, `t_escalations`.
- [ ] Write `test_cm_app_build.py` (T1): load generated JSON; assert every Switch output except `login` is reachable only through node `Auth Gate`; assert no node URL or body contains `403896149746821`; assert all Respond nodes set status codes from the table.
- [ ] Run `python scripts/test_cm_app_build.py` → FAIL (file missing).
- [ ] `build_cm_app.py`: Webhook (`responseMode: responseNode`) → `Route` (Switch on `action`) ; `login` → hash (Crypto SHA256) → Data Table lookup → token create → respond. Other actions → `Auth Gate` (Data Table `cm_app_sessions` by token, `expires_at > now`) → Switch → per action nodes. `chat` reads MySQL history + `sales_bot_user_ai_control.ai_enabled` + escalation row. `reply` facebook → HTTP Graph send (`messaging_type: RESPONSE`, BotGenius cred) then insert `messages` row sender `bot`; whatsapp → WhatsApp node with the test bot's phoneNumberId (find it in `scripts/build_whatsapp_mysql.py`). `give_back` → `SQL_UPSERT_AI_CONTROL_ON` + escalation `status=closed`.
- [ ] Run T1 → PASS.
- [ ] `push_cm_app.py`: copy `api()`/`upsert()` from `push_bosphore_fb.py`; create the 3 data tables if missing; upsert + activate. Do not run it yet.
- [ ] Commit in `PROJECTS_N8N`: `feat(cm-app): API workflow build + structure test`.
**Review:** Opus reviewer (auth + customer data).

### Task 2: (N2) Escalation sub-workflow — Opus, high
**Files:** Modify `scripts/build_cm_app.py`, `scripts/test_cm_app_build.py`; generate `workflows/cm_app/cm_app_escalate.json`.
**Interfaces:** Produces workflow "CM App Escalate" (`executeWorkflowTrigger`, inputs `userId, platform, aiOutput, errorCount, customerName`). Output = stub shape `{escalated, userId, platform, cleanOutput}`.
- [ ] Extend T1: escalate JSON has nodes `Pause Bot` (MySQL `SQL_UPSERT_AI_CONTROL_OFF`, `disabled_by='handoff'`), `Log Escalation` (data table), `FCM Push`, `WA CM Alert`; FCM and WA nodes have `onError: continueRegularOutput`; FCM body has no `customerName`/`aiOutput`.
- [ ] Run T1 → FAIL.
- [ ] Build: detect with DETECT_RESION logic (`/\[\[ESCALATE\]\]\s*$/` or `errorCount >= 3`, reason strings copied verbatim); not escalated → return `{escalated:false, cleanOutput}`. Escalated → Pause Bot → Log Escalation → FCM Push + WA CM Alert (same `notifText` format, recipient `21690431500`, phoneNumberId `1140381445805651`) → holding message `Nous vous mettons en relation avec notre équipe. Merci de patienter ⏳` (whatsapp: the Arabic text from `Set Mode + Notify CM`).
- [ ] Run T1 → PASS. Commit `feat(cm-app): escalation sub-workflow with FCM + WA alert`.
**Review:** Opus reviewer.

### Task 3: (N3) Wire BotGenius + WA test bot, push — Opus, high
**Files:** Modify `scripts/build_bosphore_fb.py` (`patch_sim_safety`: botgenius only), `scripts/build_whatsapp_mysql.py` (its handoff path near line 207), their tests `scripts/test_bosphore_build.py`.
- [ ] `SendMessage` to `projects-n8n-aa`: "CM app: I will change `patch_sim_safety` (botgenius only) + WA mysql handoff to call CM App Escalate. OK?" Wait for answer.
- [ ] Add a test in `test_bosphore_build.py`: botgenius `Handoff Check1` is `executeWorkflow` to id `escalate`; simulator keeps the Code stub; facebook build unchanged.
- [ ] Implement; run `python scripts/test_bosphore_build.py` and T1 → PASS.
- [ ] `SendMessage` to `projects-n8n-aa`: ask to run `push_cm_app.py`-dependent order: (1) I run `push_cm_app.py`, (2) that session rebuilds + pushes BotGenius and WA test. Run `push_cm_app.py` only after OK.
- [ ] Write + run `scripts/smoke_cm_app.py` (T2) against the live webhook: no token → 401; bad login → 401. Full login/give_back part runs after owner step O4.
- [ ] Commit `feat(cm-app): BotGenius + WA test escalate via CM App`.
**Review:** Opus reviewer.

## Flutter tasks (folder `Work\CM_APP`, app name `cm_app`, org `tn.microzed`)

### Task 4: (F1) Scaffold + CI — Haiku, low · skills `vgv-ai-flutter-plugin:create-project`, `green-gate`
**Files:** `pubspec.yaml`, `analysis_options.yaml` (very_good_analysis), `lib/main.dart`, `lib/app/app.dart`, `android/app/build.gradle.kts` (signing from `key.properties` if present, else debug; `com.google.gms.google-services` plugin), `.gitignore`, `.github/workflows/apk.yml`.
- [ ] `flutter create --org tn.microzed --platforms android --project-name cm_app .` (very_good CLI not installed; skip flavors).
- [ ] Add deps: flutter_bloc, bloc, equatable, go_router, http, json_annotation, flutter_secure_storage, firebase_core, firebase_messaging; dev: bloc_test, mocktail, build_runner, json_serializable, very_good_analysis.
- [ ] `apk.yml`: on push `main` + `workflow_dispatch`; `actions/checkout`, `actions/setup-java` 17, `subosito/flutter-action` (stable), decode secrets `KEYSTORE_BASE64` → `android/app/upload.jks`, write `android/key.properties` from `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`; `GOOGLE_SERVICES_JSON_BASE64` → `android/app/google-services.json`; `flutter build apk --release --dart-define=CM_API_URL=${{ vars.CM_API_URL }}`; `actions/upload-artifact` `build/app/outputs/flutter-apk/app-release.apk`.
- [ ] Check: `flutter analyze` 0 issues, `git check-ignore android/app/google-services.json android/key.properties x.jks` prints all 3. Commit `chore: scaffold cm_app + apk workflow`.

### Task 5: (F1b) DESIGN.md + app theme — Sonnet, medium · skills `vgv-ai-flutter-plugin:material-theming`, `vgv-ai-flutter-plugin:accessibility`
**Files:** Create `docs/DESIGN.md`, `lib/app/theme.dart`; modify `lib/app/app.dart` (use `AppTheme.light` / `AppTheme.dark`, `ThemeMode.system`).
**Produces:** `AppTheme.light`, `AppTheme.dark` (Material 3, `ColorScheme.fromSeed`), `AppColors.facebook`, `AppColors.whatsapp`, `AppColors.alert`. F4 uses these; no hex codes outside `theme.dart`.
- [ ] Write `docs/DESIGN.md` (1 page): palette table (token, light hex, dark hex, use), type scale (Material 3 default), spacing 4/8/16/24, 3 screen sketches (ASCII): login, alert list (row = channel chip, name, reason, time, open/closed dot), chat (header: name + channel chip + reason banner; bubbles customer left / bot+CM right; reply field; "Rendre au bot" button). Palette: seed `#0F766E` (teal), alert `#D97706`, error `#B91C1C`, Facebook chip `#1877F2`, WhatsApp chip `#25D366`. Text on chips meets WCAG AA 4.5:1 (use white on `#1877F2`, dark `#0B3D20` on `#25D366`).
- [ ] Implement `theme.dart` from DESIGN.md. Check: `flutter analyze` 0 issues; `grep -rn "Color(0x" lib --include=*.dart | grep -v theme.dart` prints nothing. Commit `feat: design doc + app theme`.

### Task 6: (F2) API client + models — Sonnet, high · skills `dart-flutter:flutter-use-http-package`, `flutter-implement-json-serialization`, `vgv-ai-flutter-plugin:layered-architecture`
**Files:** `lib/api/cm_api.dart`, `lib/api/models.dart` (+ `.g.dart`), `test/api/cm_api_test.dart`.
**Produces:** `class CmApi(http.Client client, {String baseUrl, Future<String?> Function() token})`; methods `Future<Session> login(String u, String p)`, `Future<List<Escalation>> escalations()`, `Future<Chat> chat(String senderId, String platform)`, `Future<void> reply(String senderId, String platform, String text)`, `Future<void> giveBack(String senderId, String platform)`, `Future<void> logout()`. Exceptions: `UnauthorizedException`, `InvalidLoginException`, `SendFailedException(String detail)`, `ApiException(int status)`. Models `Session{token,username,expiresAt}`, `Escalation{senderId,platform,customerName,reason,escalatedAt,status}`, `Chat{...,mode: ChatMode, messages: List<ChatMessage>}`, `ChatMessage{role,text,at}`, `enum ChatMode{human,bot}`. `baseUrl` from `String.fromEnvironment('CM_API_URL', defaultValue: 'https://n8ntest.microzed.tn/webhook/cm-app')`.
- [ ] T3: 401 on `escalations()` → throws `UnauthorizedException`. Run → FAIL → implement → PASS. green-gate. Commit.

### Task 7: (F3) Auth (login, token store, 401 → login) — Opus, high · skills `vgv-ai-flutter-plugin:bloc`, `testing`
**Files:** `lib/auth/auth_bloc.dart`, `lib/auth/token_store.dart` (flutter_secure_storage), `lib/auth/login_page.dart`, `test/auth/auth_bloc_test.dart`.
**Produces:** `AuthBloc` events `LoginSubmitted(u,p)`, `LogoutRequested`, `SessionExpired`; states `AuthUnknown`, `Unauthenticated`, `LoginInProgress`, `LoginFailure(String)`, `Authenticated(String username)`. On `Authenticated` → `PushService.subscribe()` (F5); on logout → `unsubscribe()`.
- [ ] T4 login reject → `[LoginInProgress, LoginFailure('Identifiant ou mot de passe incorrect')]`. T5 `SessionExpired` → `Unauthenticated`, token deleted. FAIL → implement → PASS. green-gate. Commit.
**Review:** Opus reviewer.

### Task 8: (F4) Escalation list + chat screen + routing — Sonnet, high · skills `vgv-ai-flutter-plugin:bloc`, `dart-flutter:flutter-setup-declarative-routing`, `flutter-add-widget-test`, `vgv-ai-flutter-plugin:material-theming`, `vgv-ai-flutter-plugin:accessibility` (Semantics labels on chips + buttons, 48dp tap targets, text scale 200% without overflow)
**Files:** `lib/app/router.dart` (`/login`, `/`, `/chat/:platform/:senderId`, redirect on auth state), `lib/escalations/escalations_cubit.dart`, `lib/escalations/escalations_page.dart`, `lib/chat/chat_cubit.dart`, `lib/chat/chat_page.dart`, `test/chat/chat_cubit_test.dart`, `test/chat/chat_page_test.dart`.
**Produces:** `ChatCubit(CmApi, senderId, platform)` with `load()`, `sendReply(String)`, `giveBack()`; state fields `chat`, `sending`, `error`, `draft`. Any `UnauthorizedException` → `AuthBloc.add(SessionExpired())`. Pull-to-refresh on both pages. Channel label `FB`/`WA`. Name fallback `Client …<last 4>`.
- [ ] T6 reply success appends `ChatMessage(role: bot)`; T7 `SendFailedException` → `error == 'Envoi impossible'`, draft kept; T8 giveBack → `chat.mode == ChatMode.bot`; T9 widget: name, reason, channel shown, empty name → fallback. FAIL → implement → PASS. green-gate. Commit.
**Review:** Opus reviewer (reply + give-back).

### Task 9: (F5) FCM push — Sonnet, high · skill `vgv-ai-flutter-plugin:bloc` (no other)
**Files:** `lib/push/push_service.dart`, `lib/main.dart` (Firebase init), `android/app/src/main/AndroidManifest.xml` (POST_NOTIFICATIONS, default channel `cm_alerts` high importance).
**Produces:** `PushService` with `subscribe()` (request permission, `subscribeToTopic('cm_bosphore')`), `unsubscribe()`, `Stream<({String senderId, String platform})> opened` fed by `onMessageOpenedApp` + `getInitialMessage`; router listens and goes to `/chat/:platform/:senderId`.
- [ ] Check: `flutter analyze` + `flutter test` green (no new test; manual check in O6). `flutter build apk --debug` fails only on missing `google-services.json` → expected locally; CI covers release. Commit.
**Review:** Opus reviewer (push).

### Task 10: (F6) Final review — Opus, high
- [ ] Dispatch agent `vgv-ai-flutter-plugin:flutter-reviewer` on the whole app. Fix blockers in the owning task's style. green-gate.

## Owner steps (stop and wait after listing)
- O1 Create private GitHub repo, push `CM_APP` `main`.
- O2 Repo secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, `GOOGLE_SERVICES_JSON_BASE64`; repo variable `CM_API_URL`.
- O3 Firebase project, Android app `tn.microzed.cm_app`, download `google-services.json`; service-account key → n8n credential "FCM service account" (Google Service Account, scope firebase.messaging); set `FCM_PROJECT_ID` in `build_cm_app.py` env.
- O4 Add CM rows in data table `cm_app_users` (hash: `python -c "import hashlib;print(hashlib.sha256(b'user:pass').hexdigest())"`).
- O5 Run GitHub Action, install APK.
- O6 Phone test on BotGenius (below).

## Verification (superpowers:verification-before-completion, spec's 4 checks)
1. Escalate on BotGenius (send a message that makes the bot end with `[[ESCALATE]]`): push on phone < 10 s (n8n execution time vs phone clock); WhatsApp CM alert also arrives.
2. Reply from app (incl. Arabic + emoji) shows in Messenger on the BotGenius page.
3. Tap "Rendre au bot", customer writes again → bot answers; `smoke_cm_app.py` full run passes.
4. 7-day watch: each `cm_app_escalations` row has a matching push (owner logs misses). Kill-app tap opens the right chat.
