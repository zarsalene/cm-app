# CM_APP — Z-Smart-CM Technical Documentation

**App Name:** Z-Smart-CM  
**Package:** `cm_app`  
**Platform:** Flutter (Android, iOS, Web)  
**Version:** 3.1.2+7  
**Flutter SDK:** `^3.47.0`  
**Dart SDK:** `^3.13.0`  
**Primary Language:** French (UI)  
**Repository:** `https://github.com/zarsalene/cm-app`

---

## 1. Project Overview

**Purpose:**  
Z-Smart-CM is a customer management mobile application for community managers (CM) to handle customer escalations and conversations across Facebook Messenger and WhatsApp. When a bot escalates a conversation to a human, the CM receives a push alert, opens the conversation, replies directly, and can hand the conversation back to the bot.

**Core user flow:**
1. Bot detects escalation → push alert sent to CM device
2. CM taps alert → app opens chat conversation
3. CM replies to customer via Messenger/WhatsApp
4. CM clicks "Rendre au bot" → conversation returns to automation, escalation marked closed

---

## 2. Architecture Pattern

**Clean Architecture with Feature-First organization:**

```
lib/
├── core/                  — Shared infrastructure (theme, connectivity, cache, errors)
├── auth/                  — Authentication (BLoC)
├── api/                   — API client + data models
├── chat/                  — Chat conversations (Cubit)
├── escalations/           — Escalation list (Cubit)
├── settings/              — Settings, theme, notifications (Cubit)
├── profile/               — User profile page
├── help/                  — Help / FAQ page
├── app/                   — App shell: router, theme, strings, drawer, splash
├── demo/                  — Fake API for browser preview (tree-shaken in prod)
├── bootstrap.dart         — App initialization
├── main_production.dart   — Production entry point
├── main_development.dart  — Development entry point
└── main_staging.dart      — Staging entry point
```

**State Management:** `bloc` / `flutter_bloc` (BLoC for auth, Cubit for chat/escalations/settings)  
**Navigation:** `go_router` (declarative, deep-linking support)  
**Localization:** `intl` + `flutter_localizations` (French UI copy centralized in `strings.dart`)  
**Theme:** Material 3 with dark mode, IBM Plex Sans Arabic font (RTL support)  
**Storage:** `flutter_secure_storage` (encrypted token), `shared_preferences` (theme preference)  
**Network:** `http` (REST client), `connectivity_plus` (online/offline monitoring)  
**Push:** `firebase_core` + `firebase_messaging` (FCM topic subscription)

---

## 3. Dependency Injection

Dependencies are provided via `MultiRepositoryProvider` in `lib/app/view/app.dart`:

| Provider | Lifetime | Responsibility |
|----------|----------|----------------|
| `TokenStore` | Singleton | Encrypted secure storage wrapper |
| `CmApi` | Singleton | REST API client, reads bearer token from `TokenStore` |
| `PushService` | Singleton | `FcmPushService` or `NoopPushService` fallback |
| `ThemeModeService` | Singleton | Theme preference persisted in `SharedPreferences` |

The `App` widget accepts optional constructor overrides for testing: `tokenStore`, `api`, `push`, `themeMode`.

---

## 4. Bootstrap Flow

**File:** `lib/bootstrap.dart`

1. Sets `FlutterError.onError` to log uncaught errors
2. Installs `AppBlocObserver` — logs all BLoC/Cubit state changes in debug mode
3. Installs global `ErrorWidget.builder` fallback — prevents red error screens from crashing the UI
4. Initializes `WidgetsFlutterBinding`
5. Loads `SharedPreferences`
6. Creates `ThemeModeService(prefs)`
7. Tries `Firebase.initializeApp()`:
   - Success → `FcmPushService` (push notifications enabled)
   - Failure (no `google-services.json`) → `NoopPushService` (app runs without push)
8. Calls `runApp(App(...))` with all injected dependencies

---

## 5. Routing Structure

**File:** `lib/app/router.dart` using `go_router`

| Route | Page | Auth Guard |
|-------|------|------------|
| `/splash` | `SplashPage` | Shown while auth state is unknown |
| `/login` | `LoginPage` | Shown when unauthenticated |
| `/` | `DashboardPage` | Requires authentication |
| `/escalations` | `EscalationsPage` | Requires authentication |
| `/chat/:platform/:senderId` | `ChatPage` | Requires authentication |
| `/settings` | `SettingsPage` | Requires authentication |
| `/profile` | `ProfilePage` | Requires authentication |
| `/help` | `HelpPage` | Requires authentication |

### Auth Redirect Logic (`authRedirect`)
- `AuthUnknown` → stay on `/splash`, otherwise redirect to `/splash`
- On `/splash` and splash not done → stay
- `Authenticated` → redirect `/login` or `/splash` to `/`
- `Unauthenticated` / `LoginInProgress` / `LoginFailure` → redirect to `/login` unless already there

### Push Target Handling
When a push notification is tapped:
1. Push data is parsed via `parsePushTarget()`
2. Validates: `sender_id` must match regex `^\d{5,32}$`, `platform` must be `facebook` or `whatsapp`
3. App navigates to `/chat/{platform}/{senderId}`
4. If tapped before login, the target is held pending and opened after authentication (max 30 minutes)

---

## 6. Theme System

**File:** `lib/app/theme.dart`

- **Material 3** (`useMaterial3: true`)
- **Color Palette:** Teal primary (`0xFF0D7A77`), Amber accent (`0xFFE68003`)
- **Dark Mode:** Complete dark theme with separate `ColorScheme.dark()`
- **Typography:** IBM Plex Sans Arabic (supports RTL for Arabic/French)
- **Component Themes:** Custom `CardTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, `InputDecorationTheme`, `ChipTheme`, `SnackBarTheme`, `DialogTheme`, `BottomSheetTheme`
- **Page Transitions:** `FadeForwardsPageTransitionsBuilder` on Android and iOS

### Theme Persistence

**File:** `lib/core/theme_mode_service.dart`

- Persists `ThemeMode.light` / `ThemeMode.dark` / `ThemeMode.system`
- Storage key: `cm_theme_mode` in `SharedPreferences`
- `brightness(context)` returns the implied `Brightness` respecting system setting
- Wired into `MaterialApp.router`'s `themeMode` parameter

---

## 7. Strings & Localization

**File:** `lib/app/strings.dart`

All UI copy is centralized in the `Strings` abstract class. Primary language is French.

**Key string categories:**

| Category | Examples |
|----------|----------|
| Auth | `loginTitle`, `loginHintUsername`, `loginHintPassword`, `loginButton`, `rememberMe`, `forgetPassword` |
| Dashboard | `dashboardTitle`, `openEscalations`, `closedEscalations`, `recentActivity`, `viewAll` |
| Escalations | `escalationsTitle`, `searchHint`, `allChannels`, `facebook`, `whatsapp`, `openSection`, `closedSection` |
| Chat | `chatTitle`, `replyHint`, `send`, `giveBack`, `botAnswersAgain`, `quickReplies` |
| Notifications | `pushActive`, `pushUnavailable`, `pushOff`, `newAlert`, `notificationsOff` |
| Settings | `appearance`, `themeMode`, `themeLight`, `themeDark`, `themeSystem`, `language`, `notifications`, `pushNotifications`, `account`, `about` |
| Help | `faqTitle`, `contactTitle`, `contactBody` |
| Errors | `noConnection`, `sendFailed`, `retry`, `otherError` |

**L10n:** `lib/l10n/l10n.dart` wraps generated `app_localizations.dart`. Extension `AppLocalizationsX` provides `context.l10n`.

---

## 8. Auth Layer

**Files:** `lib/auth/auth_bloc.dart`, `lib/auth/token_store.dart`, `lib/auth/login_page.dart`

### AuthBloc (BLoC Pattern)

**Events:**
| Event | Description |
|-------|-------------|
| `AuthStarted` | App start: restores session from secure storage |
| `LoginSubmitted` | User submits username/password with rememberMe flag |
| `LogoutRequested` | User logs out |
| `SessionExpired` | Protected API call returned 401 |

**States:**
| State | Description |
|-------|-------------|
| `AuthUnknown` | Initial state, checking secure storage |
| `Unauthenticated` | No valid session |
| `LoginInProgress` | Login request in flight |
| `LoginFailure(message)` | Login failed with user-facing message |
| `Authenticated(username)` | Successfully logged in |

**Security Properties:**
- Password is **never stored** locally
- Token + username stored in `FlutterSecureStorage` (encrypted Android KeyStore / iOS Keychain)
- Auto-restore only occurs if `rememberMe` was `true` at login
- Sequential event transformer (`bloc_concurrency`) prevents logout/login race conditions
- Storage calls wrapped in 3–5 second timeouts to prevent hangs
- `SessionExpired` does not delete token if a fresh login already occurred

### TokenStore

| Method | Description |
|--------|-------------|
| `read()` | Returns stored bearer token or null |
| `readUsername()` | Returns stored username or null |
| `readRememberMe()` | Returns whether remember-me was selected |
| `write({token, username, rememberMe})` | Saves session to secure storage |
| `delete()` | Clears all session keys |
| `testStorage()` | Verifies secure storage can write/read/delete (debug tool) |

### LoginPage
- Glassmorphism form card with teal gradient backdrop (`BrandBackdrop`)
- Username field with `AutofillHints.username`
- Password field with `AutofillHints.password` and visibility toggle
- Remember me checkbox
- Staggered fade-in + slide-up animation on load
- `ErrorBox` shown on `LoginFailure`
- Demo banner when `kDemo` is true

---

## 9. API Layer

**Files:** `lib/api/cm_api.dart`, `lib/api/models.dart`, `lib/api/models.g.dart`

### CmApi Client

**Base URL:** `https://n8ntest.microzed.tn/webhook/cm-app` (overridable via `CM_API_URL` environment variable)

**Transport:** All requests are `POST` with JSON body `{'action': <action>, ...extra}` to a single n8n webhook endpoint.

**Timeout:** 15 seconds per request

**Authentication:** Bearer token in `Authorization` header for all actions except `login`.

### API Endpoints

| Action | Method | Request | Response | Description |
|--------|--------|---------|----------|-------------|
| `login` | POST | `{username, password}` | `Session` | Authenticate user |
| `escalations` | POST | `{}` | `List<Escalation>` | List escalations (open first, newest first) |
| `chat` | POST | `{sender_id, platform}` | `Chat` | Load one conversation |
| `reply` | POST | `{sender_id, platform, text}` | — | Send text reply to customer |
| `give_back` | POST | `{sender_id, platform}` | — | Hand conversation back to bot |
| `logout` | POST | `{}` | — | End session on server |

### Exception Types

| Exception | Trigger |
|-----------|---------|
| `UnauthorizedException` | 401 status or missing token |
| `InvalidLoginException` | 401 with error `invalid_login` |
| `SendFailedException` | 502 with error `send_failed` |
| `ApiException` | Any other non-2xx HTTP status |
| `NetworkException` | Socket exception, client exception, or timeout |

### Data Models

| Model | Fields |
|-------|--------|
| `Session` | `token`, `username`, `expiresAt` |
| `Escalation` | `senderId`, `platform`, `reason`, `escalatedAt`, `status`, `customerName?` |
| `Chat` | `senderId`, `platform`, `reason`, `mode`, `messages[]`, `customerName?` |
| `ChatMessage` | `role` (`customer`/`bot`), `text`, `at?` |
| `ChatMode` | Enum: `human`, `bot` |

**Serialization:** `json_annotation` / `json_serializable` with `FieldRename.snake`. Malformed 2xx bodies surface as `ApiException(200)`, never raw `TypeError`.

### Demo API
**File:** `lib/demo/fake_cm_api.dart`  
In-memory implementation used when `kDemo` is true (browser preview). Contains scripted conversations in Tunisian darija (WhatsApp) and French (Facebook). Login credentials: `demo` / `demo`.

---

## 10. Push Service

**File:** `lib/push/push_service.dart`

### PushService Abstract Class

| Member | Description |
|--------|-------------|
| `subscribe()` | Subscribe device to FCM topic `cm_bosphore` |
| `unsubscribe()` | Unsubscribe from topic |
| `opened` | `Stream<PushTarget>` — notification tapped (cold start + `onMessageOpenedApp`) |
| `foreground` | `Stream<void>` — alert received while app is open |
| `notificationsEnabled` | `Future<bool>` — checks notification authorization status |
| `available` | `bool` — false when Firebase not initialized |

### FcmPushService
- Requests notification permission (Android 13+ `POST_NOTIFICATIONS`)
- Subscribes to topic `cm_bosphore`
- `parsePushTarget(data)` validates push data: `sender_id` must match `^\d{5,32}$`, `platform` must be `facebook` or `whatsapp`

### NoopPushService
No-op implementation for builds without Firebase configuration.

---

## 11. Dashboard & Escalations

### DashboardPage
**File:** `lib/app/dashboard_page.dart`

- Shows stat cards: open escalations, closed escalations, total, closure rate %
- Highlights urgent escalations (under 15 minutes) in amber
- Quick actions: view escalations, refresh
- Recent activity list (5 most recent escalations)
- Floating action button navigates to escalations list when open items exist
- Pull-to-refresh and pull-down refresh indicator

### EscalationsPage
**File:** `lib/escalations/escalations_page.dart`

- Search bar filtering by customer name, sender ID, or reason
- Channel filter chips: All / Facebook / WhatsApp
- Live toggle: start/stop 30-second automatic polling
- Sections: Open (amber left border) and Closed
- Skeleton loader while initial load is in progress
- Empty state with illustration when no escalations
- Error banner with retry button
- Offline notice banner when connectivity lost
- Notifications banner when push notifications are disabled
- Row tap navigates to `/chat/{platform}/{senderId}`

### EscalationsCubit
**File:** `lib/escalations/escalations_cubit.dart`

- Polls every 30 seconds when live mode is active
- Sequence number tracking prevents stale responses from overwriting newer data
- Silent refresh (no spinner) during polling; loud refresh on manual pull
- Tracks consecutive failures; marks `offline` after 2 failures
- `checkNotifications()` reads push permission status

---

## 12. Chat

**File:** `lib/chat/chat_page.dart`  
**Cubit:** `lib/chat/chat_cubit.dart`

### ChatPage Features
- App bar shows customer name, sender ID, channel chip (FB/WA)
- Back button returns to `/escalations` if no pop route exists
- "Give back" confirmation dialog (warns about unsent draft)
- Message list with day separators (Today / Yesterday / date)
- Message bubbles styled by role:
  - Customer: surface container with border
  - Bot: surface container high with bot icon
  - CM: teal gradient with checkmark
- RTL/Arabic auto-detection for message text direction
- Scroll-to-bottom floating button when user scrolls up
- Refresh indicator on pull-down
- Composer with:
  - Quick replies chips (hidden when typing)
  - Multiline text field (max 2000 chars, max 5 lines)
  - Send button with loading indicator
  - Haptic feedback on send

### ChatCubit
- Polls every 10 seconds when chat is open
- Stops polling when app is paused/hidden/detached
- `sendReply()` appends optimistic bot message, clears draft on success
- `giveBack()` sets chat mode to `bot`, marks escalation closed
- `load()` with `keepError` option preserves errors during silent refreshes
- Sequence tracking prevents refresh from undoing send/give-back results

### Message Text Cleaning
`cleanMessageText()` removes `[[ESCALATE]]` tokens and leaked prompt memory (`{"history": [...]}`) from bot messages before display.

---

## 13. New Features (Settings, Profile, Help)

### Settings Page
**File:** `lib/settings/settings_page.dart`  
**Cubit:** `lib/settings/settings_cubit.dart`

| Section | Option | Behavior |
|---------|--------|----------|
| Appearance | Theme mode | Light / Dark / System, persisted to `SharedPreferences` |
| Appearance | Language | French (placeholder for future i18n) |
| Notifications | Push notifications | Toggle subscribe/unsubscribe from FCM topic; shows active/off/unavailable |
| Account | Logout | Confirmation dialog, clears secure storage |
| Account | Reset session | Deletes stored token, forces re-login |
| Storage | Credential storage test | Verifies `FlutterSecureStorage` can write/read/delete |
| About | App version | Shows version + build number from `package_info_plus` |
| About | Developer | Microzed credit |

### Profile Page
**File:** `lib/profile/profile_page.dart`

- Circular avatar with user initial
- Username display
- Email display
- Password masked field
- Accessible from drawer → Profile

### Help Page
**File:** `lib/help/help_page.dart`

- 5 FAQ items in expandable cards:
  1. How to reply to a customer
  2. What "Rendre au bot" means
  3. Why notifications are not received
  4. Why an escalation disappears from the list
  5. Offline usage limitations
- Contact card with support email button

### Strings Added
- `appearance`, `themeMode`, `themeLight`, `themeDark`, `themeSystem`
- `language`, `notifications`, `pushNotifications`, `account`, `about`
- `faqTitle`, `contactTitle`, `contactBody`
- `resetSession`, `resetSessionSubtitle`

---

## 14. Core Infrastructure

### ThemeModeService
**File:** `lib/core/theme_mode_service.dart`
- Persists theme mode choice across app restarts
- Key: `cm_theme_mode` in `SharedPreferences`
- Modes: `system`, `light`, `dark`
- `brightness(context)` resolves to actual `Brightness` for system mode

### ConnectivityService
**File:** `lib/core/connectivity/connectivity_service.dart`
- Wraps `connectivity_plus`
- `isConnected` — true if any network interface is active
- `onConnectivityChanged` — stream of connectivity changes
- Used by `_ConnectivityOverlay` in `app/view/app.dart` to show offline banner

### ApiCache
**File:** `lib/core/cache/api_cache.dart`
- Generic in-memory key-value cache with TTL (default 5 minutes)
- Lazy expiry eviction on read
- `JsonCache` wrapper for typed JSON encode/decode
- `debugDump()` logs live cache entries in debug mode

### ErrorBoundary
**File:** `lib/core/error/error_boundary.dart`
- Widget that catches errors in descendants
- Renders fallback UI with retry callback instead of red error screen
- `installGlobalErrorWidget()` installs global `ErrorWidget.builder` for unhandled build errors

---

## 15. App Shell

### Files in `lib/app/`
| File | Responsibility |
|------|----------------|
| `app.dart` | Exports theme + view |
| `view/app.dart` | `MaterialApp.router`, ThemeModeService provider, connectivity overlay |
| `router.dart` | GoRouter configuration, auth redirect, push target handling |
| `theme.dart` | Material 3 light/dark themes, spacing, radius, shadows, colors |
| `strings.dart` | All French UI copy |
| `splash_page.dart` | Animated splash screen with logo, progress bar |
| `dashboard_page.dart` | Dashboard with stats, quick actions, recent activity |
| `app_drawer.dart` | Navigation drawer with profile, settings, help, logout, app status |
| `channel_chip.dart` | FB/WA platform chip |
| `brand_backdrop.dart` | Logo-colored gradient backdrop |
| `credit_line.dart` | "Développé par Microzed" footer |
| `motion_widgets.dart` | `LiveDot` (pulsing indicator), `SpinRefreshButton` |

### Offline Banner
Shown at top of app when `connectivity_plus` reports no network interface. Amber background with cloud_off icon and "Hors ligne" text.

---

## 16. Entry Points

| File | Flavor | Notes |
|------|--------|-------|
| `main_production.dart` | Production | `bootstrap((push, themeMode) => App(push: push, themeMode: themeMode))` |
| `main_development.dart` | Development | Same as production |
| `main_staging.dart` | Staging | Same as production |

Each calls `bootstrap()` which initializes Firebase, push service, theme service, then runs `App`.

---

## 17. Testing

**Test files in `test/`:**

| File | Coverage |
|------|----------|
| `test/api/cm_api_test.dart` | API client: escalations 401 → `UnauthorizedException` |
| `test/app/facebook_escalation_flow_test.dart` | Integration: splash → login → list → chat → reply → give back |
| `test/auth/auth_bloc_test.dart` | AuthBloc: login success/failure, session expiration |
| `test/chat/chat_cubit_test.dart` | ChatCubit: send reply, send failed, give back |
| `test/chat/chat_page_test.dart` | ChatPage: displays name, reason, channel |
| `test/escalations/escalation_arrival_test.dart` | New escalation appears on refresh, channel filter works |
| `test/helpers/pump_app.dart` | Test helper: bounded pumpAndSettle |
| `test/helpers/helpers.dart` | Exports pump_app |

**Test runner:** `flutter test` — all 13 tests pass.

---

## 18. n8n Workflows

**Directory:** `n8n/`

### Workflow 1 — Vitrine (Landing Page)
- **File:** `vitrine_cm_app.workflow.json`
- **Webhook:** `GET /webhook/z-smart-cm`
- **Public URL:** `https://n8ntest.microzed.tn/webhook/z-smart-cm`
- **Nodes:** Webhook → Code (builds HTML from `vitrine.js`) → Respond (HTML)
- **Source:** `vitrine.js` contains full HTML/CSS (dark theme, teal/orange, responsive)
- **Sections:** Hero, Features (6 cards), How it works (4 steps), Screens, Error messages, CTA band, Footer

### Workflow 2 — APK Download
- **File:** `apk-download.workflow.json`
- **Webhook:** `GET /webhook/z-smart-cm-download`
- **Public URL:** `https://n8ntest.microzed.tn/webhook/z-smart-cm-download`
- **Behavior:** 302 redirect to `https://github.com/zarsalene/cm-app/releases/download/v3.1.2/Z-Smart-CM.apk`

### Deployment
- `python -I n8n/push_pages.py` — creates/updates both workflows via n8n API, activates vitrine
- Requires `N8N_API_URL` and `N8N_API_KEY` environment variables

---

## 19. CI/CD (GitHub Actions)

**File:** `.github/workflows/release.yml`

**Trigger:** Push tag matching `v*` (e.g. `git tag v0.2.0 && git push --tags`)

**Flow:**
1. Build production APK
2. Create GitHub Release (pre-release) with APK attached
3. Download URL: `https://github.com/zarsalene/cm-app/releases/download/v3.1.2/Z-Smart-CM.apk`
4. n8n APK download workflow redirects to this URL

**Important:** Without `google-services.json` added as secret, CI-built APK runs without FCM push (app works, no notifications).

---

## 20. User Accounts & Security

**Table:** `cm_app_users` (n8n Data Tables)

**Password hash:** `sha256(username + ':' + password)` in lowercase hex

**Generate hash (PowerShell):**
```powershell
$u="agent2"; $p="motdepasse";
$bytes=[Text.Encoding]::UTF8.GetBytes("$u`:$p");
$sha=[Security.Cryptography.SHA256]::Create();
($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
```

Add `(username, password_hash)` row to the table — the app logs in immediately.

### Security Incident (2026-11-03)
- `password_hash` previously contained plaintext passwords — corrected to SHA-256
- User `arsalene` password circulated in plaintext
- **Required action:** Recalculate hash, update table row

---

## 21. Credentials & Remember Me (Current Status)

**How it works:**
1. On login page, check **« Se souvenir de moi »** (Remember me)
2. Token + username saved to `FlutterSecureStorage` (encrypted)
3. On app start, if remember-me is true, session is restored automatically
4. Password is **never stored**

**Debug tools added:**
- Settings → Stockage: tests if secure storage works on the device
- Settings → Compte → Réinitialiser la session: clears stored token and logs out
- Debug logs in `auth_bloc.dart` and `token_store.dart` visible in Logcat

---

## 22. Build & Run Commands

```bash
# Get dependencies
flutter pub get

# Analyze code
flutter analyze lib/

# Run all tests
flutter test

# Build APK (development)
flutter build apk --debug

# Build APK (production)
flutter build apk --release

# Run on connected device
flutter run

# Run with specific flavor
flutter run -t lib/main_production.dart
```

---

## 23. Folder Reference

```
C:\Users\zarsa\Desktop\Work\CM_APP\
├── lib/
│   ├── bootstrap.dart
│   ├── main_production.dart
│   ├── main_development.dart
│   ├── main_staging.dart
│   ├── core/
│   │   ├── theme_mode_service.dart
│   │   ├── connectivity/connectivity_service.dart
│   │   ├── cache/api_cache.dart
│   │   └── error/error_boundary.dart
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── token_store.dart
│   │   └── login_page.dart
│   ├── api/
│   │   ├── cm_api.dart
│   │   ├── models.dart
│   │   └── models.g.dart
│   ├── chat/
│   │   ├── chat_cubit.dart
│   │   └── chat_page.dart
│   ├── escalations/
│   │   ├── escalations_cubit.dart
│   │   └── escalations_page.dart
│   ├── settings/
│   │   ├── settings_cubit.dart
│   │   └── settings_page.dart
│   ├── profile/
│   │   └── profile_page.dart
│   ├── help/
│   │   └── help_page.dart
│   ├── app/
│   │   ├── router.dart
│   │   ├── theme.dart
│   │   ├── strings.dart
│   │   ├── splash_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── app_drawer.dart
│   │   ├── channel_chip.dart
│   │   ├── brand_backdrop.dart
│   │   ├── credit_line.dart
│   │   └── motion_widgets.dart
│   ├── app/view/app.dart
│   ├── push/push_service.dart
│   └── demo/fake_cm_api.dart
├── n8n/
│   ├── vitrine_cm_app.workflow.json
│   ├── apk-download.workflow.json
│   ├── vitrine.js
│   ├── push_pages.py
│   └── *.ps1
├── test/
├── assets/
│   ├── logo/
│   └── fonts/
├── docs/
├── .github/workflows/release.yml
├── pubspec.yaml
└── PROJECT_DOCUMENTATION.md
```

---

*End of documentation.*