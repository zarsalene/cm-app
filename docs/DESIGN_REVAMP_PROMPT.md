# Z-Smart-CM: design revamp prompt

Use this prompt for a design and implementation pass on the Flutter app in this repo. It is based on a read-only scan of the "Rattil" Quran app (`Desktop\Work\Quran_rectitaion_APP`), which the owner likes, compared with the current screens of this app.

## 1. Goal

Make Z-Smart-CM look as polished as Rattil: calm, warm, consistent, with a strong hero area, quiet outlined cards, one accent color, and excellent Arabic text. Keep the purpose of the app: community managers (CMs) handle customer chats that the chatbot escalated. The interface is in French. Customer messages arrive in French, Tunisian darija (Arabic script), Arabizi, or a mix of them, with emojis and digits. Arabic must look excellent and read right-to-left per message.

## 2. Hard constraints (do not break)

- Keep the Z-Smart-CM brand: teal `#0F766E` as primary and amber `#D97706` as the accent. The logo files have white backgrounds (`assets/logo/icon_1024.png`, `wordmark.png`, `microzed.jpeg`), so keep logos on white or light plates.
- BLoC for state, go_router for navigation. Do not change behavior, API calls, auth, push or polling. This is a visual pass.
- No hex color literal may appear in code outside `lib/app/theme.dart`. All colors live in the theme.
- Test cap: the project has 10 tests at most (it has 9 now). Add no new tests unless one pure function needs it. Keep the existing tests green.
- Accessibility: contrast at least 4.5:1 for text, 48 dp touch targets, Semantics labels, no information by color alone (always an icon or a text label as well), everything usable at 200% text scale, and every animation must respect `MediaQuery.disableAnimations`.
- Reliability first: no change may delay or hide an alert, a reply or the "Rendre au bot" action.
- Keep all French strings in `lib/app/strings.dart` (the login page still has some inline strings: move them).
- Follow the existing code style (the project uses recent Dart syntax; check the Dart version before pasting snippets from other projects).

## 3. Do NOT copy from Rattil

- Religious content: the 8-point star motif and lattice, ayah medallions, surah banners, mosque, qibla or prayer icons, the Quran text fonts (Amiri Quran, the five qiraat fonts), the "Rattil" name and logo, its copy.
- Any Quran data or the AI-generated image at the root of that repo.
- If a pattern is wanted, use a neutral geometric pattern or none.
- Safe to copy: generic design tokens (radii, spacing, durations), the "border instead of shadow" approach, the component structure, and the theme code pattern.

## 4. Design tokens to adopt

Color roles (by role, so dark mode comes almost for free):

| Role | Light | Dark |
|---|---|---|
| primary | `#0F766E` (teal) | `#2DB1A5` |
| primaryContainer | `#D3EEEA` | `#0F3F3A` |
| deep teal (hero gradient end) | `#0A4F49` | `#0A4F49` |
| secondary / accent (amber) | `#D97706` | `#F3C06B` |
| secondaryContainer | `#FBE8C8` | `#3A2C12` |
| surface (warm paper) | `#FAF8F3` | `#0D1412` |
| surfaceContainer (cards) | `#FFFFFF` | `#151F1C` |
| surfaceContainerHigh | `#F2EFE6` | `#1C2925` |
| outlineVariant (hairlines) | `#E4DFD0` | `#2C3A35` |
| ink (text) | `#1C2622` | `#E7E3D8` |
| onSurfaceVariant | `#5F6B66` | `#A9B3AE` |

Check every text and background pair at 4.5:1 and write the ratios in `docs/DESIGN.md`. Keep the existing channel colors (Facebook `#1877F2` with black text, WhatsApp `#25D366` with dark green text).

Typography:
- Bundle IBM Plex Sans Arabic (SIL OFL 1.1) at 400, 500, 600 and 700 as the single UI font. It covers Arabic and Latin, so darija looks the same on every phone. Do not rename or modify the font files (reserved font name "Plex"). Ship the OFL license text in the assets and list it in the app's licenses. Do not use Amiri Quran.
- TextTheme: headlineMedium w700 (letter spacing -0.3), titleLarge w700, titleMedium w600, labelLarge w600, bodyLarge 16 with height 1.55 (chat text), secondary text 12 to 13.5 in onSurfaceVariant.
- App bar title: 19 sp w700, centered.

Shape and elevation:
- Radii: chip 12, button 16, card 20, hero 28, dialog 28, bottom sheet top 28, snackbar 14, bubble 20.
- Cards: elevation 0 with a 1 px outlineVariant border. Shadows only on floating bars (blur 16, offset 0,-4, 8% black).
- Spacing: page gutter 16, vertical rhythm 8, 12, 16, 24, inner card padding 16. Add `AppRadius` (12/16/20/28) next to `AppSpacing`.

Component themes to add in `theme.dart`: Card, FilledButton (min height 52, radius 16), InputDecoration (filled, no outline until focus, 2 px teal focus border, radius 16), AppBar, Dialog, BottomSheet, SnackBar (floating), Chip, PageTransitions (fade-forwards, off when animations are disabled). Light and dark ThemeData both complete.

## 5. Screen by screen

### 5.1 Splash
1. Keep the white page (the logos have white boxes). Add a soft teal radial wash at the bottom edge (4 to 8% opacity) for depth.
2. Staggered motion: icon scales 0.8 to 1.0 with easeOutBack (600 ms), wordmark slides up 12 dp and fades in (300 ms). Add a thin 3 dp teal progress line or a pulsing amber dot while auth loads.
3. Credit at the bottom: "Développé par" and the Microzed logo, with a hairline above.
4. Reduce motion: static logos, no delay (keep the existing rules: never delay an alert, 1 second minimum otherwise).

### 5.2 Login
1. Hero panel at the top: teal to deep-teal gradient, radius 28, with the icon on a white rounded plate (96 to 120 dp). Use the real app name "Z-Smart-CM" (the page still says "CM App").
2. The form sits in a Card (radius 20, 1 px border, padding 20). Filled inputs, 56 dp high, prefix icons (person, lock), a show or hide toggle on the password, hint text instead of a floating label.
3. Errors in an inline rounded errorContainer box with an icon, not bare red text.
4. Primary button 52 dp, spinner inside at 20 dp while the label stays.
5. Footer: hairline divider, "Développé par" and the Microzed logo (28 dp). The footer must not push the form off-screen with the keyboard open or at 200% text scale.
6. Move the inline French strings to `Strings`.

### 5.3 Alert list (home)
1. Group with section titles "Ouvertes" and "Fermées": a 4 x 18 amber rounded bar, titleMedium text and a count.
2. Each alert is a Card (radius 20, outlined), 16/12 padding, 8 dp gap between cards. Layout: a 44 dp circular tonal avatar with initials (primaryContainer), and a small channel badge in its corner (the real Facebook or WhatsApp color, radius 8, with a text label for accessibility). Then the customer name (w700 when open), the reason on one line (ellipsis, onSurfaceVariant), and a time pill at the end.
3. Open alerts get a 4 dp amber border at the start edge (`BorderDirectional`) and a 10 dp amber dot. Closed alerts are muted (no border, onSurfaceVariant).
4. Time pill: radius 20, amber container when the alert is under 15 minutes old, neutral otherwise. Relative French text ("il y a 5 min").
5. Banners: the "Notifications désactivées" notice becomes a rounded amber-container card with an icon and an "Activer" action (no full-width red strip). The offline notice becomes a small pill with a `cloud_off_rounded` icon.
6. Empty state: a 96 dp tonal circle with `mark_chat_read_rounded`, a titleMedium line ("Aucune escalade") and a short subtitle. Loading: three skeleton cards instead of a bare spinner. Errors: icon, text and a retry button.
7. Motion: new rows fade in and slide up 8 dp (200 ms, only the first 8). A light haptic when a new alert arrives (`HapticFeedback.lightImpact`).
8. Keep the logout action, but make it a clear icon button with a tooltip and Semantics label.

### 5.4 Chat
1. Header: customer name (Arabic names must render right-to-left), channel badge and the reason. The reason becomes a rounded card (radius 16, amber container) with a flag icon and a "Motif" label, collapsible after the first view, capped in height.
2. Bubbles, radius 20 with one tighter 4 dp corner on the sender side:
   - Customer: white surfaceContainer with a 1 px outlineVariant border, on the left.
   - Bot: surfaceContainerHigh with a small "Bot" label, on the right.
   - CM (our replies): solid teal with white text, on the right. This separates the three roles. Check 4.5:1.
3. Per-message direction (very important): detect the direction from the first strong letter (Arabic or Hebrew ranges = right-to-left, otherwise left-to-right; empty or digits only = left-to-right). Apply `textDirection` to each message text and `TextAlign.start`. Keep the bubble side by role, independent of the text direction. Mixed French and Arabic, emojis and Western digits must stay correct. Use bodyLarge 16 with height 1.6 in Plex Arabic. The time stays left-to-right digits at the bubble end. Message text is selectable so a CM can copy it.
4. Date separator pills ("Aujourd'hui", "Hier") in labelSmall, group consecutive messages (4 dp inside a group, 12 dp between senders), time inside the bubble in 11 to 12 sp onSurfaceVariant.
5. Composer: a floating bar (surfaceContainer, radius 24, 1 px border, elevation 2, margin 12) with a borderless multi-line field (hint "Votre réponse", max 2000 characters), and a 48 dp filled circular send button in teal. The field direction follows what is typed (listener on the controller).
6. "Rendre au bot": move it away from the send area, into the app bar (an icon button with text on wide screens or an overflow item), or a tonal pill above the composer, never next to the send button. The confirmation dialog uses the new dialog style (radius 28, icon in a tonal circle, FilledButton and TextButton) and keeps the "Le texte non envoyé sera perdu." warning.
7. When the bot is active again: a tonal card with a robot icon and "Le bot répond de nouveau", in place of the composer.
8. Motion: a new bubble slides up 8 dp and fades in (200 ms). A light haptic on send. A "scroll to latest" button appears when the user scrolled up. Keep the scroll rules: only auto-scroll if the user was at the bottom.
9. Errors ("Envoi impossible", "Pas de connexion") appear as an inline notice above the composer, and the typed text stays.

### 5.5 Dialogs, notices, snackbars (cross-cutting)
1. One notice component with 3 tones (info teal, warning amber, error) used for notifications-off, offline and chat errors: radius 16, icon, text, optional action.
2. Dialogs: radius 28, a 40 to 56 dp tonal icon circle, titleLarge, FilledButton plus TextButton.
3. Snackbars floating, radius 14, 4 seconds. The foreground alert snackbar keeps its text "Nouvelle alerte client" with an "Ouvrir" action if possible.
4. Dark mode must be complete and checked on all screens.

## 6. Acceptance checks

1. `flutter analyze`: no issues. `dart format --set-exit-if-changed lib test`: clean. All existing tests pass (run with the Very Good CLI MCP test tool, not `flutter test`).
2. `grep -rn "Color(0x" lib --include=*.dart | grep -v theme.dart` prints nothing.
3. Contrast ratios written in `docs/DESIGN.md`, all at least 4.5:1.
4. In the browser preview (`flutter run -d chrome -t lib/main_development.dart --dart-define=DEMO=true`, login `demo` / `demo`): check the 5 screens in light and dark, at 360 px width and at 200% text scale, with the Arabic demo chats (alignment, punctuation, mixed text, emojis).
5. No behavior change: login, polling, push navigation, reply, give-back, the 401 path.
6. Update `docs/DESIGN.md` (Brand and tokens) and keep the font license text in the assets.
