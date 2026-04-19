# Character display names, archetypes & taglines

Character *codenames* (Monty, Fernie, Cleo, Suzy, Ollie, **Pip**) stay in English — they're proper nouns, same as on the marketing site. Only the **archetypes** and **taglines** change per locale.

These keys are **already present** in both `en.lproj/Localizable.strings` and `de.lproj/Localizable.strings` — see the `// MARK: - Characters` section of each file. This doc is the cross-reference.

## Wiring up `CharacterCatalog.swift`

Replace the hard-coded English `archetype` / `tagline` strings with `String(localized:)` lookups:

```swift
var archetype: String {
    String(localized: String.LocalizationValue("character.\(rawValue).archetype"))
}

var tagline: String {
    String(localized: String.LocalizationValue("character.\(rawValue).tagline"))
}
```

(Keys are `character.monty.archetype`, `character.monty.tagline`, etc.)

## Full key reference

### en.lproj
```
"character.monty.archetype"   = "Monstera";
"character.monty.tagline"     = "Big leaves, bigger drinks.";
"character.fernie.archetype"  = "Fern";
"character.fernie.tagline"    = "Keep me misted, keep me happy.";
"character.cleo.archetype"    = "Cactus";
"character.cleo.tagline"      = "Forgetful owners welcome.";
"character.suzy.archetype"    = "Succulent";
"character.suzy.tagline"      = "A little water goes a long way.";
"character.ollie.archetype"   = "Olive / Citrus";
"character.ollie.tagline"     = "Mediterranean and chill.";
"character.pip.archetype"     = "Pilea peperomioides";
"character.pip.tagline"       = "Round coin leaves, easy-going soul.";
```

### de.lproj
```
"character.monty.archetype"   = "Monstera";
"character.monty.tagline"     = "Große Blätter, großer Durst.";
"character.fernie.archetype"  = "Farn";
"character.fernie.tagline"    = "Besprüh mich, halt mich glücklich.";
"character.cleo.archetype"    = "Kaktus";
"character.cleo.tagline"      = "Vergessliche Besitzer willkommen.";
"character.suzy.archetype"    = "Sukkulente";
"character.suzy.tagline"      = "Ein bisschen Wasser reicht schon.";
"character.ollie.archetype"   = "Olive / Zitrus";
"character.ollie.tagline"     = "Mediterran und entspannt.";
"character.pip.archetype"     = "Pilea peperomioides";
"character.pip.tagline"       = "Runde Münzblätter, gelassenes Gemüt.";
```
