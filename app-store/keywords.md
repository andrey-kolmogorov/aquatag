# App Store Keywords

App Store Connect → AquaTag → App Store tab → 1.0 version → **Keywords** field.
Limit: 100 characters per locale. Comma-separated, no spaces between terms.

Notes:
- Words already in App Name and Subtitle are auto-indexed — do not repeat them here.
- Singular forms usually match plural searches via stemming.
- Multi-word brand terms (`homeassistant`) are combined as one token to target brand match.

---

## English (en-US)

97 characters.

```
houseplant,gardening,reminder,plantcare,journal,homeassistant,nabucasa,smarthome,automation,garden
```

## Deutsch (de-DE)

94 Zeichen.

```
Zimmerpflanze,Garten,Erinnerung,Pflege,Tagebuch,Botanik,HomeAssistant,NabuCasa,SmartHome,Topf
```

---

## Deliberately omitted

- `nfc`, `watering`, `tracker` / `gießen` — already in subtitle.
- `aquatag` — auto-indexed via app name.
- `plants` / `Pflanzen` — already covered by subtitle or stem-matching.
- `iot`, `cactus`, `succulent` — too generic or too narrow.
