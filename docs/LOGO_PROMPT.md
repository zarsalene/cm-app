# Z-Smart-CM: logo prompts

Use these prompts in an AI image model. The name "Z-Smart-CM" is general: it is not tied to Le Bosphore, so it works for any shop.

Colors come from `docs/DESIGN.md`: deep teal `#0F766E` and amber `#D97706`.

## 1. App icon (use this first)

The icon has no text. Image models often misspell words, and text is unreadable at icon size.

```
Minimal flat vector app icon for "Z-Smart-CM", a smart assistant for community managers who handle customer chats. A rounded chat bubble in deep teal (#0F766E) with a bold, geometric letter "Z" formed by a lightning-bolt-like zigzag inside it, and a small amber (#D97706) dot at the top right corner of the bubble like a notification. Clean modern geometry, thick simple shapes, 2 colors plus white, no gradients, no shadows, no outlines. Centered on a solid white square background, with generous empty space around the symbol (the symbol fills about 60% of the canvas). Looks sharp and readable at 48x48 pixels. Professional tech brand style. 1024x1024, square.
```

Negative prompt:

```
text, words, letters other than the single Z, photo, 3D, realistic, gradient, glow, shadow, thin lines, busy details, mockup, phone frame, watermark
```

## 2. Wordmark (splash screen, marketing)

```
Horizontal logo lockup: the same teal chat bubble with a "Z" zigzag and an amber notification dot, next to the text "Z-Smart-CM" in a clean bold geometric sans-serif font, dark teal text (#0F766E), flat vector, transparent or white background, wide 4:1 layout.
```

## 3. Other concepts (optional)

Chat bubble with a handoff arrow (bot passes the chat to a person):

```
Minimal flat vector app icon for "Z-Smart-CM": a teal (#0F766E) rounded chat bubble and a small amber (#D97706) arrow curving out of it toward a simple person silhouette, showing a chat handed from a bot to a human. Two colors plus white, thick simple shapes, no gradients, no shadows, solid white square background, symbol fills 60% of the canvas, readable at 48x48 pixels, 1024x1024.
```

Letters only:

```
Minimal flat vector app icon: bold geometric letters "ZCM" in white on a deep teal (#0F766E) rounded square, a small amber (#D97706) dot at the top right corner, no gradients, no shadows, readable at 48x48 pixels, 1024x1024.
```

## Tips

- Generate 4 versions and pick the simplest one.
- Shrink each one to 48 px. Keep the one that still reads.
- Ask for a PNG at 1024x1024 with a solid background (not transparent).
- Keep the symbol inside the middle 66% of the canvas. Android crops the icon edges into a circle or a rounded square.

## Next step

1. Save the chosen PNG as `assets/logo/icon_1024.png` in the project.
2. Tell Claude. It then makes the Android launcher icons, renames the app on the phone to "Z-Smart-CM", and updates the theme colors if you change them.
