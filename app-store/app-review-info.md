# App Review Information

App Store Connect → AquaTag → App Store tab → 1.0 version → **App Review Information**.

---

## Contact

| Field | Value |
|---|---|
| First Name | Andrei |
| Last Name | Kolmogorov |
| Phone Number | *(mobile with country code)* |
| Email Address | andrew.kolmogorov@gmail.com |

## Sign-In Required

**No.** AquaTag works fully without authentication. Demo account fields left blank.

## Attachment

Optional. A 10-second screen recording of a successful NFC scan is a strong addition for an NFC app — removes reviewer ambiguity.

---

## Notes (paste into the Notes field — 4000 chars max)

```
PURPOSE
AquaTag is a plant-watering tracker. Users register houseplants, tap to log a watering, and optionally sync each event to a personal Home Assistant instance. NFC is a convenience shortcut, not a requirement — every feature is reachable via on-screen taps.

NO ACCOUNT REQUIRED
The app works fully on first launch without sign-in or external setup. Data is stored locally with SwiftData. No analytics or third-party SDKs.

HOW TO TEST CORE FUNCTIONALITY (NO NFC NEEDED)
1. Open the app. The Plants tab is selected by default.
2. Tap the "+" button (top right) to add a plant.
3. Pick any of the six characters (Monty, Fernie, Cleo, Suzy, Ollie, or Pip), enter a name, and tap Save.
4. On the plant card, tap the green water-drop button to log a watering. The card updates with the timestamp.
5. Switch to the History tab to see a six-week heatmap and weekly stats.
6. Switch to the Settings tab to see Home Assistant configuration (optional, see below).

NFC TESTING (OPTIONAL — REQUIRES PHYSICAL NFC STICKER)
The app uses NFCNDEFReaderSession to read user-written NFC stickers (NTAG213/215/216 are typical):
1. From a plant's detail screen, tap "Write Tag" and hold a blank NDEF sticker near the iPhone. The app writes the URI "aquatag://water/<plantID>".
2. Tap the same sticker again from outside the app. iOS opens AquaTag automatically and logs a watering.

If no NFC sticker is available, the same code path can be exercised via the URL scheme:
- In Safari, type: aquatag://water/test-plant-01
  (Replace test-plant-01 with the ID shown in any plant's detail page.)
- iOS will route to AquaTag and log a watering for that plant.

HOME ASSISTANT (OPTIONAL — NOT REQUIRED FOR REVIEW)
The Home Assistant section in Settings is optional. Leaving it blank does not affect any other feature. If you wish to test it, point the URL field to any HA instance reachable from the device and provide a long-lived access token. Otherwise skip — all other functionality is independent.

LOCALISATION
The app is fully localised in English and German. To verify the German build, change device language: Settings > General > Language & Region > iPhone Language > Deutsch.

DATA & PRIVACY
- Plant data: SwiftData, on-device only.
- Home Assistant token (when entered): iOS Keychain, transmitted only to the user-configured HA URL over HTTPS.
- No analytics, no tracking, no third-party SDKs, no remote logging.
- Privacy policy: https://aquatag.app/privacy

CONTACT FOR REVIEW QUESTIONS
Email: andrew.kolmogorov@gmail.com
Support: https://aquatag.app/support
```
