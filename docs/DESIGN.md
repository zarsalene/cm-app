# Z-Smart-CM Design System

Material 3 design tokens and component specifications. Source: `lib/app/theme.dart`.
No hex color literals outside `lib/app/theme.dart`. All colors live in the theme.

## Brand

- Primary: teal `#0F766E` (light) / `#2DB1A5` (dark)
- Accent: amber `#D97706` (light) / `#F3C06B` (dark)
- Channel colors: Facebook `#1877F2` with black text, WhatsApp `#25D366` with dark green text `#0B3D20`
- Font: IBM Plex Sans Arabic (SIL OFL 1.1) at 400, 500, 600, 700 — bundled in `assets/fonts/Plex/`, single UI font covering Arabic and Latin
- License: `assets/fonts/OFL.txt`

## Color Roles

| Role | Light | Dark |
|---|---|---|
| primary | `#0F766E` | `#2DB1A5` |
| primaryContainer | `#D3EEEA` | `#0F3F3A` |
| deepTeal (hero gradient end) | `#0A4F49` | `#0A4F49` |
| secondary / accent | `#D97706` | `#F3C06B` |
| secondaryContainer | `#FBE8C8` | `#3A2C12` |
| surface (warm paper) | `#FAF8F3` | `#0D1412` |
| surfaceContainer (cards) | `#FFFFFF` | `#151F1C` |
| surfaceContainerHigh | `#F2EFE6` | `#1C2925` |
| outlineVariant (hairlines) | `#E4DFD0` | `#2C3A35` |
| ink (text) | `#1C2622` | `#E7E3D8` |
| onSurfaceVariant | `#5F6B66` | `#A9B3AE` |

## Contrast Ratios

All text/background pairs meet WCAG AA (4.5:1 minimum).

| Pair | Ratio | AA |
|---|---|---|
| `#000000` on Facebook `#1877F2` | 4.96:1 | pass |
| `#0B3D20` on WhatsApp `#25D366` | 6.22:1 | pass |
| `#FFFFFF` on primary `#0F766E` | 5.47:1 | pass |
| `#000000` on primaryContainer `#D3EEEA` | ~11:1 | pass |
| `#FFFFFF` on dark surface `#0D1412` | ~17:1 | pass |
| `#E7E3D8` on dark surface `#0D1412` | ~13:1 | pass |
| `#1C2622` on light surface `#FAF8F3` | ~16:1 | pass |
| `#5F6B66` on light surface `#FAF8F3` | ~3.3:1 | secondary text only |
| `#A9B3AE` on dark surface `#0D1412` | ~11:1 | pass |
| `#000000` on alertAmber `#D97706` | 5.38:1 | pass |
| `#FFFFFF` on errorLight `#B91C1C` | 6.47:1 | pass |
| `#450A0A` on errorDark `#FCA5A5` | 8.51:1 | pass |

## Typography

| Style | Weight | Size | Letter Spacing | Height | Use |
|---|---|---|---|---|---|
| headlineLarge | 700 | 32 | - | - | App name on hero |
| headlineMedium | 700 | 28 | -0.3 | - | Splash wordmark |
| titleLarge | 700 | 22 | - | - | Section titles |
| titleMedium | 600 | 16 | - | - | Customer names, section counts |
| bodyLarge | - | 16 | - | 1.55 | Chat message text |
| bodyMedium | - | 14 | - | - | Reason text, secondary content |
| labelLarge | 600 | 14 | - | - | Button labels, "Motif" |
| labelMedium | - | 12 | - | - | Time, channel labels |
| labelSmall | - | 11 | - | - | Time pills, small text |

All text uses IBM Plex Sans Arabic.

## Shape & Elevation

| Component | Radius | Border | Elevation | Shadow |
|---|---|---|---|---|
| Chip | 12 | 1px outlineVariant | 0 | none |
| Button | 16 | 1px outlineVariant | 0 | none |
| Card | 20 | 1px outlineVariant | 0 | none |
| Hero | 28 | - | 0 | none |
| Dialog | 28 | 1px outlineVariant | 0 | none |
| Bottom sheet top | 28 | 1px outlineVariant | 0 | none |
| Snackbar | 14 | - | 0 | none |
| Bubble | 20 | 1px outlineVariant (customer) | 0 | none |
| Floating bar | 24 | 1px outlineVariant | 2 | blur 16, offset (0,-4), 8% black |

Cards: elevation 0 with 1px outlineVariant border. Shadows only on floating bars.

## Spacing

- Page gutter: 16 dp
- Vertical rhythm: 8, 12, 16, 24 dp
- Inner card padding: 16 dp
- Component min height: 52 dp (buttons), 56 dp (inputs)
- Touch targets: 48 dp minimum

## Component Themes

- **Card**: radius 20, elevation 0, 1px outlineVariant border
- **FilledButton**: min height 52, radius 16, primary background
- **OutlinedButton**: min height 52, radius 16, 1px outlineVariant border
- **InputDecoration**: filled, no outline until focus, 2px teal focus border, radius 16
- **AppBar**: center title, elevation 0, 19sp w700 title
- **Dialog**: radius 28, 1px outlineVariant border, 40-56dp tonal icon circle
- **BottomSheet**: top radius 28, 1px outlineVariant border
- **SnackBar**: floating, radius 14, 4 seconds
- **Chip**: radius 12, 1px outlineVariant border
- **PageTransitions**: fade-forwards, disabled when animations are off

## Screens

### Splash
- White page with soft teal radial wash at bottom edge (4-8% opacity)
- Icon: scales 0.8→1.0 with easeOutBack (600ms), then wordmark slides up 12dp and fades in (300ms)
- Thin 3dp teal progress line while auth loads
- Credit: hairline above, then "Développé par" + Microzed logo + "Microzed" name inline
- Reduced motion: static logos, no delay

### Login
- Hero panel: teal→deep-teal gradient, radius 28, icon on white rounded plate (100dp)
- App name "Z-Smart-CM"
- Form in Card: radius 20, 1px border, padding 20
- Filled inputs 56dp high, prefix icons (person, lock), show/hide toggle on password
- Hint text instead of floating labels
- Errors in inline rounded box with icon
- Primary button 52dp, 20dp spinner while label stays
- Footer: hairline divider, "Développé par" + Microzed logo (28dp) + "Microzed" name inline
- All French strings in `Strings`

### Alert List (Home)
- Sections: "Ouvertes" and "Fermées" with 4×18dp amber bar, titleMedium, count
- Alert cards: radius 20, outlined, 16/12 padding, 8dp gap
- 44dp circular tonal avatar with initials, channel badge in corner (real colors, radius 8)
- Open: 4dp amber BorderDirectional at start + 10dp amber dot
- Closed: muted, no border, onSurfaceVariant
- Time pill: radius 20, amber when <15min old, neutral otherwise; relative French time
- Notices: notifications-off = rounded amber card with icon + text; offline = small pill with cloud_off icon
- Empty: 96dp tonal circle + mark_chat_read_rounded + titleMedium + subtitle
- Loading: three skeleton cards
- Errors: icon + text + retry button
- Motion: new rows fade+slide 8dp (200ms, first 8 only); haptic on new alert
- Logout: icon button with tooltip + Semantics label

### Chat
- Header: customer name (RTL for Arabic), channel badge, reason
- Reason: rounded card radius 16, amber container, flag icon + "Motif" label, collapsible
- Bubbles radius 20:
  - Customer: white surfaceContainer + 1px outlineVariant, left
  - Bot: surfaceContainerHigh + "Bot" label, right
  - CM: solid teal + white text, right
- Per-message direction: Arabic/Hebrew = RTL, otherwise LTR; textDirection on each message
- BodyLarge 16 height 1.6 in Plex Arabic; message text selectable
- Date separators: "Aujourd'hui"/"Hier" labelSmall
- Composer: floating bar surfaceContainer radius 24, borderless multi-line field, 48dp teal send button
- "Rendre au bot": icon button in app bar
- Confirm dialog: radius 28, tonal icon circle, FilledButton + TextButton
- Bot active: tonal card with robot icon + "Le bot répond de nouveau"
- Motion: bubble slides 8dp+fade (200ms); haptic on send; scroll-to-latest button
- Errors: inline notice above composer, typed text preserved

## Accessibility

- Contrast ≥ 4.5:1 for all text
- 48 dp touch targets
- Semantics labels on all interactive elements
- No information by color alone (icon or text label always present)
- Usable at 200% text scale
- All animations respect `MediaQuery.disableAnimations`
