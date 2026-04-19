# AquaTag Design Handoff

Visual redesign package for the AquaTag iOS app. Drop-in SwiftUI files, Xcode asset catalog, tokenised design system. Matches the marketing site and sticker kit.

---

## What's in the box

```
design-handoff/
├── DesignSystem/
│   ├── DesignSystem.swift         # Colors, typography, spacing, radius, shadow, motion
│   └── CharacterCatalog.swift     # Character enum + Plant.character convenience
├── Components/
│   ├── CharacterView.swift        # Reusable avatar (small/medium/large/hero)
│   ├── PlantRowView.swift         # Drop-in replacement
│   └── WateringStatusBadge.swift  # Drop-in replacement
├── Views/
│   ├── ContentView.swift          # Brands the TabBar
│   ├── PlantListView.swift
│   ├── PlantDetailView.swift
│   ├── AddPlantView.swift
│   ├── WateringHistoryView.swift
│   └── SettingsView.swift
├── Models/
│   └── MigrationNotes.swift       # Plant.characterID field guidance
└── Assets.xcassets/
    ├── Colors/AT/                 # 18 branded color sets (light + dark)
    └── Characters/AT/Character/   # 6 character SVG imagesets
```

---

## Install steps (Xcode)

1. **Merge the asset catalog.** Open `AquaTag/Assets.xcassets` in Xcode. Drag the two folders from `design-handoff/Assets.xcassets/` — `Colors/` and `Characters/` — into the catalog. Xcode reads the `Contents.json` namespaces automatically (`AT/...`, `AT/Char/...`, `AT/Character/...`).

2. **Add the Swift files.** Drop in matching locations under `AquaTag/`:
   - `DesignSystem/DesignSystem.swift` → new folder `AquaTag/DesignSystem/`
   - `DesignSystem/CharacterCatalog.swift` → same folder
   - `Components/*.swift` → `AquaTag/Views/Components/` (overwrites existing `PlantRowView.swift`, `WateringStatusBadge.swift`)
   - `Views/*.swift` → `AquaTag/Views/` (overwrites 5 files)
   - `Views/ContentView.swift` → `AquaTag/` (overwrites)

   The project uses `PBXFileSystemSynchronizedRootGroup`, so Xcode auto-picks up files from disk — no pbxproj edits.

3. **Update the `Plant` model** — add one optional field. See `Models/MigrationNotes.swift` for the exact diff. SwiftData handles this as a lightweight migration; no schema version bump needed.

4. **Bundle fonts** (see below).

5. **Build & run.** First launch: existing plants show as Monty (default fallback). Edit any plant to reassign to any of the 6 characters.

---

## Fonts

The design system references three Google Fonts. Download the TTFs and add them to the target (check "Copy items" + "Add to target: AquaTag").

| Family | Files | Where used |
|---|---|---|
| [Fraunces](https://fonts.google.com/specimen/Fraunces) | `Fraunces-Regular.ttf`, `Fraunces-Medium.ttf` | Display serif — plant names, counters, titles |
| [IBM Plex Sans](https://fonts.google.com/specimen/IBM+Plex+Sans) | `IBMPlexSans-Regular.ttf`, `IBMPlexSans-Medium.ttf`, `IBMPlexSans-SemiBold.ttf` | Body UI |
| [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono) | `IBMPlexMono-Regular.ttf`, `IBMPlexMono-Medium.ttf` | Entity IDs, eyebrows, timestamps |

Add to `Info.plist`:

```xml
<key>UIAppFonts</key>
<array>
    <string>Fraunces-Regular.ttf</string>
    <string>Fraunces-Medium.ttf</string>
    <string>IBMPlexSans-Regular.ttf</string>
    <string>IBMPlexSans-Medium.ttf</string>
    <string>IBMPlexSans-SemiBold.ttf</string>
    <string>IBMPlexMono-Regular.ttf</string>
    <string>IBMPlexMono-Medium.ttf</string>
</array>
```

**Fallback strategy:** `Font.custom(...)` silently falls back to system San Francisco if the file is missing. If you ship without the fonts, the app still works — it just looks generic.

---

## Design tokens — quick reference

### Colours (light / dark)

| Token | Hex (light) | Purpose |
|---|---|---|
| `AT/BG` | `#F6EFDF` | Page background, cream |
| `AT/Paper` | `#FFF9EC` | Card surface |
| `AT/Ink` | `#1B2A1A` | Primary text |
| `AT/InkSoft` | `#5A6B57` | Secondary text |
| `AT/InkMute` | `#8A9786` | Tertiary text |
| `AT/Moss` | `#2D8C4E` | Primary brand, CTAs |
| `AT/Terracotta` | `#C8463A` | Overdue / destructive |
| `AT/Amber` | `#E8A020` | Due-soon warning |

Dark mode variants live in each `.colorset`'s `Contents.json`. Backgrounds go deep moss (`#1B2A1A`) and ink inverts to cream.

### Type scale

| Token | Family · Size · Weight |
|---|---|
| `displayXL` | Fraunces · 56 · Regular |
| `displayL` | Fraunces · 40 · Regular |
| `displayM` | Fraunces · 28 · Medium |
| `displayS` | Fraunces · 22 · Medium |
| `title` | Plex Sans · 20 · SemiBold |
| `headline` | Plex Sans · 17 · SemiBold |
| `body` | Plex Sans · 16 · Regular |
| `subhead` | Plex Sans · 14 · Medium |
| `caption` | Plex Sans · 13 · Regular |
| `micro` | Plex Sans · 11 · Medium |
| `eyebrow` | Plex Mono · 11 · Medium (uppercase + 2pt tracking) |
| `mono` | Plex Mono · 13 · Regular |

### Spacing (4pt grid)

`xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 48 · xxxl 64`

Screen-edge horizontal padding: `screenEdge = 20`.

### Radius

`xs 6 · sm 10 · md 14 · lg 20 · xl 28 · pill 999`

Cards use `md` (14). Large cards / row tiles use `lg` (20). Buttons + status badges use `pill`.

### Shadow

- `card` — resting tiles. `rgba(0,0,0,0.06)` · r12 · y4
- `raised` — FAB, sheets. `rgba(0,0,0,0.10)` · r20 · y8
- `nav` — hairline under scrolled nav. `rgba(0,0,0,0.04)` · r6 · y2

### Motion

- `quick` — spring 0.28 / 0.85 (taps, toggles)
- `smooth` — spring 0.42 / 0.80 (sheet transitions)
- `soft` — ease-out 0.35 (fades)

---

## Character system

**6 hero characters**, one per flag color. Each has a species archetype, hero color, flag stake color, and sticker artwork. Stored on `Plant.characterID` as the enum rawValue. Enum case order matches the kit-box layout (green → blue → yellow → red → pink → white).

| # | Character | Species | Flag stake | Hex | Suggested interval |
|---|---|---|---|---|---|
| 1 | Monty  | Monstera              | Green  | `#2DB489` | 7 days  |
| 2 | Fernie | Fern                  | Blue   | `#1E6AA8` | 4 days  |
| 3 | Suzy   | Succulent             | Yellow | `#E9B82A` | 14 days |
| 4 | Cleo   | Cactus                | Red    | `#C8201E` | 21 days |
| 5 | Ollie  | Olive / Citrus        | Pink   | `#E8388A` | 10 days |
| 6 | Pip    | Pilea peperomioides   | White  | `#F5F2EA` | 7 days  |

The SVG artwork in the imagesets matches the 25mm sticker files from `stickers-and-flags.html` — same characters, same paint-matched palette, cleaned of print-only elements (cut guides, bleed markers). Pip's artwork is unique: high-contrast dark greens with inky outlines, since the white flag demands ink-based rendering.

---

## Screen-by-screen changes

### Plants (`PlantListView`)
- Custom branded header ("Aquatag" wordmark + leaf mark) replaces the emoji navtitle
- Eyebrow "NURSERY" + Fraunces "N plants" count as list hero
- Cards on cream background instead of grouped List cells
- Rows use `CharacterView` (was emoji), Fraunces plant name, pill status badge, moss drop button
- Floating "Scan sticker" capsule spans full width at the bottom, raised shadow
- Empty state uses the hero Monty character

### Plant detail (`PlantDetailView`)
- Hero character (160pt) + Fraunces name + archetype eyebrow
- 3-stat strip (Every / Last / Next) in separate cards
- Sections rendered as independent cards (Watering, Notes, NFC, HA) instead of grouped Form
- Destructive delete rendered as a subdued terracotta-tinted button
- Toolbar buttons tinted moss (confirm) / ink-soft (cancel)

### Add plant (`AddPlantView`)
- Horizontal scrolling character picker with selection ring in character color
- Tagline updates beneath picker as character changes
- Watering interval auto-suggests the character's recommended cadence
- HA entity preview card tinted moss — reassurance, not a warning
- No more emoji grid

### Watering history (`WateringHistoryView`) — "Six weeks of care"
Rebuilt to match the marketing prototype's History screen:
- Eyebrow "THE LAST SIX WEEKS" + Fraunces display "History"
- Big stats row: **total waterings** (terracotta) + **day streak** (ink) — uses `AquaTag.Typography.displayXL`
- **7 × 6 heatmap** — rows are weekdays (Mon-first, locale-aware), columns are the 6 most recent weeks. Empty tiles use `divider`; watered tiles use `moss` with opacity scaling from 0.3 → 1.0 based on daily activity.
- "THIS WEEK" list below — character avatar + plant name + relative "when · who" line + drop glyph, one row per watering in the last 7 days (max 5).
- `heatmapBuckets(from:)` is self-contained and works off whatever `WateringEvent` stream the app produces — swap in `WateringLog` @Model results when that lands.

### Settings (`SettingsView`)
- 4 cards: Home Assistant, Device, Reminders, Plant Helpers
- Custom form fields with mono micro labels
- "Test connection" renders as an outlined moss button; success/fail inline
- Plant Helpers list shows each plant with its character + entity ID

### Tab bar
- Branded moss selected color, paper background, custom `UITabBarAppearance` set in `ContentView.init`

---

## Localization — EN + DE

Lives in `Localization/` and is ready to wire up:

- `en.lproj/Localizable.strings` — source locale, all user-facing copy extracted from the views.
- `de.lproj/Localizable.strings` — Deutsch translation. Tone is **du**, not Sie, matching the marketing site. Section headers stay ALL CAPS to preserve the app's visual rhythm (`KINDERSTUBE`, `RHYTHMUS`, `GIESSEN ALLE`).
- `L10n.swift` — typed accessor so call sites stay readable (`Text(L10n.Plants.headerEyebrow)`, `L10n.Status.overdue(days: 3)`).
- `CharacterNames.strings.md` — archetype/tagline keys for all **6** characters (Monty, Fernie, Cleo, Suzy, Ollie, Pip) in both locales. Keys are already present in `en.lproj` / `de.lproj`; doc shows how to wire `CharacterCatalog.swift` to read them. Character proper nouns stay English in both locales.
- `README.md` — Xcode wiring, call-site patterns, plural notes, QA via scheme language override.

Views in this handoff still hold English literals. Replace with `L10n.*` keys as part of PR 3, or split into PR 4 if you'd rather land the redesign and the localization pass separately.

---

## What's NOT included

- **App icon.** The existing `AppIcon.appiconset` is untouched. If you want a new one that matches, export the moss + leaf mark from the landing page at 1024×1024 and drop into the existing iconset. I can generate this as a follow-up.
- **Animations beyond tokens.** `AquaTag.Motion` defines curves; views mostly use them on the character picker selection. Can be applied liberally to sheet presentations, water button taps, etc.
- **Dark mode review.** Color sets have dark variants, but the app hasn't been viewed end-to-end in dark mode. Eye-ball after first build.

---

## Recommended PR order

1. **PR 1 — Design system + assets.** Add `DesignSystem/`, `Assets.xcassets` additions, fonts, and the model migration. No visual changes yet (the new files aren't referenced by any view).
2. **PR 2 — CharacterView + badge.** Replace `WateringStatusBadge.swift`, add `CharacterView.swift`, update `PlantRowView.swift`. Already produces a visible change: branded row styling.
3. **PR 3 — Views.** Replace the 5 view files. Optional: do detail and add-plant first (most visual impact) before list and settings.
4. **PR 4 — Localization.** Add the `Localization/` folder, register `de` on the project, and swap English literals in the views for `L10n.*` keys. Can ship alongside PR 3 if you prefer.

Each PR stands alone; intermediate states still compile.

---

## Questions?

- Ping me if the Character enum conflicts with any existing type in the codebase — rename to `PlantCharacter` if so.
- If SwiftData migrations need a schema version bump, let me know and I'll supply a `SchemaV2` sketch.
