# App Store Description

App Store Connect → AquaTag → App Store tab → 1.0 version → **Description** field.
Limit: 4000 characters per locale. Cannot be edited without a new version.

---

## English (en-US)

~2,030 characters.

```
Tap your iPhone to a plant pot. The watering is logged. That is the entire workflow.

AquaTag turns ordinary NFC stickers into watering shortcuts. Stick a tag on each pot, scan once to assign a plant, then every later tap records a watering — no typing, no menus, no opening the app first.

HOW IT WORKS
1. Add a plant in the app. AquaTag generates a unique ID.
2. Hold a blank NFC sticker to your iPhone and write the ID.
3. Stick the tag on the pot. From now on, tap to water.

For iPhones without NFC, or anyone who would rather skip the tags, AquaTag also has a regular tap-to-water button on every plant card. NFC is the shortcut, not a requirement.

FEATURES
• Six hand-illustrated plant characters — Monty, Fernie, Cleo, Suzy, Ollie, and Pip — each with a recommended watering rhythm.
• Visual schedule shows which plants are due, overdue, or freshly watered.
• Six-week history with a heatmap of waterings per day and weekly stats per plant.
• Local notifications remind you when a plant is overdue.
• Available in English and German throughout.

HOME ASSISTANT (OPTIONAL)
If you run Home Assistant via Nabu Casa, AquaTag can sync each watering as an aquatag_plant_watered event and update an input_datetime helper per plant. Use it to trigger automations, dashboards, or any workflow you have already built. Setup is two fields: your Nabu Casa URL and a long-lived access token.

PRIVACY
AquaTag stores everything on your device. No analytics, no third-party SDKs, no cloud account. Your Home Assistant token lives in the iOS Keychain and is only sent to your own server. Full policy at aquatag.app/privacy.

OFFLINE-FIRST
Watering is recorded the instant you tap, even without a connection. If Home Assistant sync fails, the event waits in a queue and retries automatically when the network comes back.

REQUIREMENTS
• iPhone with NFC reading (iPhone 7 or newer).
• iOS 17 or later.
• NFC stickers that support NDEF (NTAG213/215/216 work well).
• Optional: a Nabu Casa subscription for Home Assistant sync.

Questions? aquatag.app/support
Privacy policy: aquatag.app/privacy
```

---

## Deutsch (de-DE)

~2,180 Zeichen.

```
Halte dein iPhone an den Blumentopf. Das Gießen ist protokolliert. Das ist der komplette Ablauf.

AquaTag macht aus gewöhnlichen NFC-Stickern Gieß-Shortcuts. Klebe einen Tag auf jeden Topf, ordne ihn einmal einer Pflanze zu, und jeder weitere Tap protokolliert das Gießen – kein Tippen, keine Menüs, kein vorheriges Öffnen der App.

SO FUNKTIONIERT'S
1. Lege eine Pflanze in der App an. AquaTag erzeugt eine eindeutige ID.
2. Halte einen leeren NFC-Sticker an dein iPhone und schreibe die ID.
3. Klebe den Tag auf den Topf. Ab jetzt: antippen zum Gießen.

Für iPhones ohne NFC oder alle, die lieber ohne Tags arbeiten, gibt es zu jeder Pflanze auch eine normale Gieß-Schaltfläche. NFC ist der Shortcut, keine Voraussetzung.

FUNKTIONEN
• Sechs handgezeichnete Pflanzenfiguren – Monty, Fernie, Cleo, Suzy, Ollie und Pip – jede mit einem empfohlenen Gieß-Rhythmus.
• Visuelle Übersicht zeigt, welche Pflanzen fällig, überfällig oder frisch gegossen sind.
• Sechs-Wochen-Verlauf mit Heatmap aller Gießvorgänge und Wochenstatistik pro Pflanze.
• Lokale Benachrichtigungen, wenn eine Pflanze überfällig ist.
• Vollständig auf Deutsch und Englisch.

HOME ASSISTANT (OPTIONAL)
Wer Home Assistant über Nabu Casa nutzt, kann jedes Gießen als aquatag_plant_watered-Event synchronisieren und pro Pflanze einen input_datetime-Helper aktualisieren. Damit lassen sich Automationen, Dashboards oder eigene Workflows auslösen. Einrichtung: zwei Felder – Nabu-Casa-URL und ein Long-Lived Access Token.

DATENSCHUTZ
AquaTag speichert alles auf deinem Gerät. Keine Analytik, keine Drittanbieter-SDKs, kein Cloud-Account. Dein Home-Assistant-Token liegt im iOS-Schlüsselbund und wird ausschließlich an deinen eigenen Server gesendet. Vollständige Datenschutzerklärung: aquatag.app/privacy.

OFFLINE-FIRST
Das Gießen wird sofort protokolliert, auch ohne Verbindung. Schlägt die Home-Assistant-Synchronisation fehl, bleibt das Event in der Warteschlange und wird automatisch erneut versucht, sobald wieder Netz verfügbar ist.

VORAUSSETZUNGEN
• iPhone mit NFC-Leser (iPhone 7 oder neuer).
• iOS 17 oder neuer.
• NFC-Sticker mit NDEF-Unterstützung (NTAG213/215/216 funktionieren gut).
• Optional: ein Nabu-Casa-Abo für die Home-Assistant-Synchronisation.

Fragen? aquatag.app/support
Datenschutz: aquatag.app/privacy
```
