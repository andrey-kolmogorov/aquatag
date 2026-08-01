# AquaTag

I kept forgetting which plants I'd watered. So I stuck NFC tags on each pot — tap with my iPhone, watering logged, Home Assistant updated, no app to open. AquaTag is that app.

<!-- TODO: insert hero screenshot or 15s demo GIF here -->

Open-source under MIT. iOS 17+, Swift 6, no cloud, no account, no analytics.

Don't want to source NFC tags and color-coded labels yourself? **[aquatag.app](https://aquatag.app)** sells starter kits with NFC tags, plant flags, sticker characters, and a setup card.

[<img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on the App Store" height="50">](https://apps.apple.com/app/id6763767959)

## Features

- **NFC tap to log** — scan a sticker on the pot, watering recorded instantly
- **Home Assistant integration** — every tap fires events and updates entities you can build automations on (see [HOME_ASSISTANT.md](HOME_ASSISTANT.md))
- **Auto-creates HA helpers** — no manual entity setup per plant
- **Smart reminders** — local notifications based on per-plant watering intervals
- **Offline-first** — saves locally, queues failed syncs, retries on next launch
- **Write NFC tags** — program blank NTAG stickers directly from the app
- **Multi-device** — household members log waterings independently from their own iPhones
- **Localized** — English and German (Deutsch); contributions for additional locales welcome

## Requirements

- iPhone 7+ with iOS 17.0+
- [Home Assistant](https://home-assistant.io) with [Nabu Casa](https://nabucasa.com) remote access — see [HOME_ASSISTANT.md](HOME_ASSISTANT.md#setup) for setup
- NFC stickers (NTAG213 recommended — cheapest, plenty of storage)

## Quick start

1. **Install** from the App Store (link above) or build from source.
2. **Connect to Home Assistant** — open Settings, paste your Nabu Casa URL and a Long-Lived Access Token, tap **Test Connection**. Detailed steps in [HOME_ASSISTANT.md](HOME_ASSISTANT.md#setup).
3. **Add a plant** — tap `+`, fill in name, emoji, and watering interval. The corresponding HA helper is created automatically.
4. **Stick an NFC tag on the pot** and write the plant's ID via plant detail → **Write to NFC Tag**.
5. **Tap the tag when you water.** Done.

## Privacy

AquaTag does not collect, transmit, or analyze any personal data. Your Home Assistant URL and access token are stored only on your device — the URL in the local SwiftData store, the token in the iOS Keychain. The app talks directly to your Home Assistant instance and to nothing else. There is no AquaTag server.

## Architecture

Swift 6, SwiftUI, SwiftData, CoreNFC. Zero external dependencies.

```
AquaTag/
├── Models/          Plant, AppSettings, PendingWateringEvent (@Model)
├── ViewModels/      PlantListViewModel, SettingsViewModel (@Observable @MainActor)
├── Views/           PlantList, PlantDetail, AddPlant, History, Settings
│   └── Components/  PlantRowView, WateringStatusBadge
├── Services/        NFCService, HAService, KeychainService, NotificationService
└── Utilities/       PlantIDGenerator, DateFormatters
```

**Key patterns:**

- MVVM with service layer
- Async/await throughout (no completion handlers)
- HA token in iOS Keychain, never in SwiftData
- Offline queue (`PendingWateringEvent`) for failed HA calls
- `PBXFileSystemSynchronizedRootGroup` — Xcode auto-discovers files from disk

## Building

```bash
# Simulator
xcodebuild -scheme AquaTag -destination 'generic/platform=iOS Simulator'

# Device
xcodebuild -scheme AquaTag -destination 'generic/platform=iOS'
```

Requires Xcode 16+. No SPM/CocoaPods — all Apple frameworks.

### Building from source (forkers)

To build and run on your own device:

1. Change the bundle identifier in `AquaTag.xcodeproj` — `com.andreiapps.AquaTag` is registered to the original author.
2. Set your own development team in **Signing & Capabilities** for the `AquaTag` target.
3. Provision the **Near Field Communication Tag Reading** capability — this requires a paid Apple Developer account (free accounts can't sign apps with the NFC entitlement).

Simulator builds work without code signing if you only need to exercise the non-NFC paths (NFC isn't available in the simulator anyway).

## Contributing

This is a side project I maintain when I have time. PRs welcome for:

- Bug fixes
- Home Assistant integration improvements
- Accessibility / VoiceOver fixes
- Additional localizations (English and German exist; `Localizable.xcstrings` is the entry point)
- Automation cookbook contributions in [HOME_ASSISTANT.md](HOME_ASSISTANT.md)

Less likely to merge: features that significantly expand scope, external dependencies, anything that requires server-side infrastructure. Please open an issue first if you want to discuss a larger change — that saves both of us time.

## AquaTag the brand vs. AquaTag the code

The MIT license covers the iOS app source in this repository. You're free to fork, modify, and ship it under your own name.

What's **not** covered by the MIT license:

- The **AquaTag** name and logo
- The [aquatag.app](https://aquatag.app) website and shop
- Physical NFC kits, packaging, and printed materials sold under the AquaTag brand

If you fork and redistribute, please use a different product name — this avoids confusion over which kits are officially supported.

## License

[MIT](LICENSE) — © 2026 Andrei Kolmogorov.
