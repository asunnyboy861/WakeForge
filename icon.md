# App Icon

## Generation Prompt
WakeForge iOS app icon, a glowing dumbbell merged with a rising sun, the dumbbell bar acts as the horizon line, large dominant subject filling the entire square frame, edge-to-edge composition, no padding, no margin, solid deep black background, ember orange and sunrise gold glow, flat bold vector shapes, professional, clean, no text, no words, no letters, square format, 1024x1024

## Generated Image
- Source: `icon_raw.png` (Agnes Image 2.1 Flash, 1 attempt)
- Final: `icon_1024.png` → `WakeForge/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Style: deep-black background, glowing dumbbell whose bar reads as the horizon, sun disc behind it in ember orange → sunrise gold
- Alpha channel: none (verified with `sips -g hasAlpha` → `no`)
- Pixel size: 1024 × 1024 RGB

## Asset Catalog
- `AppIcon.appiconset` configured with the single 1024 universal slot: ✅
- Xcode generates the remaining sizes from the 1024 asset: ✅
- Accent color set to Forge Orange `#FF6A00`: ✅

## Rationale
The mark reads as both a dumbbell and a sunrise, which is exactly the product's promise: fitness + waking up. The high-contrast glow survives the small home-screen size, and the near-black field keeps the icon calm next to the system UI.
