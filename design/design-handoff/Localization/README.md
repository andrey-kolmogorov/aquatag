# Localization — English + Deutsch

AquaTag ships bilingual out of the box. All user-facing copy lives in
`Localizable.strings`; no hard-coded English literals in views.

## File layout

```
Localization/
├── en.lproj/Localizable.strings      ← source locale (English)
├── de.lproj/Localizable.strings      ← Deutsch
├── L10n.swift                        ← typed accessor (enum L10n { … })
├── CharacterNames.strings.md         ← character archetype + tagline keys
└── README.md                         ← this file
```

## How to add to Xcode

1. Drag the `en.lproj` and `de.lproj` folders into the Xcode project navigator
   as **folder references** (blue folder icon). Xcode auto-recognizes `.lproj`
   and registers both as localizations on the project.
2. Add `de` to **Project → Info → Localizations** if it isn't already.
3. Drop `L10n.swift` into the `DesignSystem/` group (or its own
   `Localization/` group — either is fine).
4. In the existing `CharacterCatalog.swift`, swap the hard-coded English
   `archetype` / `tagline` for `String(localized:)` lookups against the keys
   documented in `CharacterNames.strings.md`.

## Call-site pattern

Before:

```swift
Text("NURSERY")
Text("\(plants.count) plants")
Text("\(plant.name) is already watered enough. Water anyway?")
```

After:

```swift
Text(L10n.Plants.headerEyebrow)
Text(L10n.Plants.count(plants.count))
Text(L10n.Plants.alreadyBody(plantName: plant.name))
```

**Rule of thumb:** `LocalizedStringKey` for static strings passed straight to
`Text`, `Label`, `navigationTitle`, etc. `String(localized:)` via the helper
functions on `L10n` for anything with `%@` / `%d` substitutions.

## Plurals

We branch on `count == 1` for `plants.header.count` inside
`L10n.Plants.count(_:)`. When you want full ICU plural rules (German has two
plural forms; English has one), promote that key to a `Localizable.stringsdict`
entry. Format lives on Apple's docs — the helper function's signature stays
identical, so no call-site changes.

## German copy tone

- `du`, not `Sie` — matches the marketing site's voice.
- Plant-forward vocabulary: *Kinderstube* (nursery), *Gieß-Protokoll*
  (watering log), *Pflanzen-Helfer* (plant helpers).
- Keep compound words; avoid hyphenating unless a word is genuinely unfamiliar
  (`Home-Assistant-Entity` is the one exception — three proper nouns).
- Section headers stay ALL CAPS, matching the English rhythm of the UI.

## Testing

- **Scheme language override:** Product → Scheme → Edit Scheme → Run → Options →
  App Language → *Deutsch*. Relaunch on simulator.
- **Per-app language on device:** Settings → Aquatag → Sprache.
- **Pseudolocalization:** set App Language to *Double-Length Pseudolanguage* to
  catch truncation and RTL-adjacent layout bugs.

## Not yet localized

- `AppIcon.appiconset` — icon is language-agnostic.
- Home Assistant entity IDs — deliberately English-only; they're machine keys,
  not UI copy.
- Character proper nouns (Monty, Fernie, Cleo, Suzy, Ollie, Pip) — stay
  English in both locales by design. Their archetypes and taglines *are*
  translated — see `CharacterNames.strings.md`.
