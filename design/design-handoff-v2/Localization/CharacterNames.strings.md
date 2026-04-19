# Character display names & taglines

Character *codenames* (Monty, Fernie, Cleo, Suzy, Ollie, Bram) stay in English — they're proper nouns, same as in the marketing site. Only the **taglines** and **archetypes** change per locale.

Wire these up in `CharacterCatalog.swift` by replacing the hard-coded `displayName` / `tagline` / `archetype` strings with `String(localized:)` lookups against these keys, then add both `en.lproj` and `de.lproj` entries below.

## Keys

```
// en.lproj/Localizable.strings
"character.monty.archetype"   = "The optimist";
"character.monty.tagline"     = "Sunshine and sturdy leaves.";
"character.fernie.archetype"  = "The dreamer";
"character.fernie.tagline"    = "Thrives in soft, quiet corners.";
"character.cleo.archetype"    = "The diva";
"character.cleo.tagline"      = "Dramatic, but worth the fuss.";
"character.suzy.archetype"    = "The free spirit";
"character.suzy.tagline"      = "Happy dangling from anywhere.";
"character.ollie.archetype"   = "The survivor";
"character.ollie.tagline"     = "Forgets to ask for water.";
"character.bram.archetype"    = "The steady one";
"character.bram.tagline"      = "Grows slow, grows strong.";

// de.lproj/Localizable.strings
"character.monty.archetype"   = "Der Optimist";
"character.monty.tagline"     = "Sonne und kräftige Blätter.";
"character.fernie.archetype"  = "Die Träumerin";
"character.fernie.tagline"    = "Gedeiht in stillen, weichen Ecken.";
"character.cleo.archetype"    = "Die Diva";
"character.cleo.tagline"      = "Dramatisch, aber den Aufwand wert.";
"character.suzy.archetype"    = "Der Freigeist";
"character.suzy.tagline"      = "Hängt fröhlich von überall herunter.";
"character.ollie.archetype"   = "Der Überlebenskünstler";
"character.ollie.tagline"     = "Vergisst, nach Wasser zu fragen.";
"character.bram.archetype"    = "Der Beständige";
"character.bram.tagline"      = "Wächst langsam, wächst stark.";
```
